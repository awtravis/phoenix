# Anisotropy tests
# Simple test microstructure for a U4O9 domain in a UO2 matrix
# Starting concentration c = 0.15
# Deeper energy well = 10

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 100
  ny = 100
  nz = 0
  xmin = 0
  xmax = 20
  ymin = 0
  ymax = 20
  elem_type = QUAD4
[]

[MeshModifiers] #Adds a new node set
  [./new_nodeset]
    type = AddExtraNodeset
    coord = '5 5'
    new_boundary = 100
  [../]
[]

[Variables]
  # Oxygen concentration within the microstructure
  [./c]
    order = FIRST
    family = LAGRANGE
  [../]
  # Chemical potential
  [./w]
    order = FIRST
    family = LAGRANGE
  [../]
  # Phase field variable
  [./eta]
    order = FIRST
    family = LAGRANGE
  [../]
  [./T] #Temperature used for the direct calculation
    initial_condition = 800
  [../]
[]

[ICs]
  # UO2 = 0.0 and U4O9 = 0.25
  [./concentrationIC]
    type = SmoothCircleIC
    variable = c
    x1 = 10.0
    y1 = 10.0
    radius = 3.0
    invalue = 0.15
    outvalue = 0.15
    int_width = 0.1
  [../]
  # UO2 = 0.0 and U4O9 = 1.0
  [./etaIC]
    type = SmoothCircleIC
    variable = eta
    x1 = 10.0
    y1 = 10.0
    radius = 3.0
    invalue = 1.0
    outvalue = 0.0
    int_width = 0.1
  [../]
[]

[BCs]
  [./Periodic]
    [./All]
      auto_direction = 'x y'
    [../]
  [../]
  [./left_T] #Fix temperature on the left side
    type = PresetBC
    variable = T
    boundary = left
    value = 800
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-6
  [../]
[]

[Kernels]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
  [./ACBulk]
    type = ACParsed
    variable = eta
    args = c
    f_name = F
  [../]
  [./ACInterface]
    type = ACInterface
    variable = eta
    kappa_name = kappa_eta
  [../]

  [./c_res]
    type = SplitCHParsed
    variable = c
    f_name = F
    kappa_name = kappa_c
    w = w
    args = 'eta'
  [../]
  [./w_res]
    type = SplitCHWRes
    variable = w
    mob_name = M
  [../]
  [./time]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]

  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]
[]

[Materials]
  [./consts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L kappa_eta'
    prop_values = '1 1'
  [../]
  [./consts2]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'M kappa_c'
    prop_values = '1 1'
  [../]

  [./switching]
    type = SwitchingFunctionMaterial
    block = 0
    eta = eta
    h_order = HIGH
  [../]
  [./barrier]
    type = BarrierFunctionMaterial
    block = 0
    eta = eta
    g_order = SIMPLE
  [../]

  # Free energy of UO2 matrix
  [./free_energy_A]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fa
    args = 'c'
    function = '(100*(c^2))'
    derivative_order = 2
    enable_jit = true
  [../]
  # Free energy of U4O9 domain
  [./free_energy_B]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fb
    args = 'c'
    function = '(100)*((0.25-c)^2)'
    derivative_order = 2
    enable_jit = true
  [../]

  [./free_energy]
    type = DerivativeTwoPhaseMaterial
    block = 0
    f_name = F
    fa_name = Fa
    fb_name = Fb
    args = 'c'
    eta = eta
    derivative_order = 2
    outputs = exodus
    output_properties = 'F dF/dc dF/deta d^2F/dc^2 d^2F/dcdeta d^2F/deta^2'
  [../]

  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_b k_p2 k_int'
    constant_expressions = '1e-6 5 1 0.1'
    function = 'sk_b:= length_scale*k_b; sk_p2:= length_scale*k_p2; sk_int:= k_int*length_scale; if(eta>0.1,if(eta>0.95,sk_p2,sk_int),sk_b)'
    outputs = exodus
    f_name = thermal_conductivity
    args = eta
  [../]
[]

[Postprocessors]
  [./right_T]
    type = SideAverageValue
    variable = T
    boundary = right
  [../]
  [./k_x_direct] #Effective thermal conductivity from direct method
    # This value is lower than the AEH value because it is impacted by second phase
    # on the right boundary
    type = ThermalCond
    variable = T
    flux = 5e-6
    length_scale = 1e-06
    T_hot = 800
    dx = 10
    boundary = right
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  scheme = 'bdf2'
  solve_type = 'NEWTON'

  l_max_its = 15
  l_tol = 1.0e-4

  nl_max_its = 10
  nl_rel_tol = 1.0e-6

  start_time = 0.0
  num_steps = 200

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = .001 # Initial time step.  In this simulation it changes.
    optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  exodus = true
[]
