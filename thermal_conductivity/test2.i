# Microstructure for multiple U4O9 domains in a UO2 matrix
# Initial test condition with c = 0.042

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 25
  ny = 25
  nz = 0
  xmin = 0
  xmax = 25
  ymin = 0
  ymax = 25
  elem_type = QUAD4
  uniform_refine = 2
[]

[Variables]
  # Oxygen concentration within the microstructure
  [./c]
    order = FIRST
    family = LAGRANGE
  [../]
  # Energy barrier
  # Default value equal to 1
  [./w]
    order = FIRST
    family = LAGRANGE
  [../]
  # Phase field variable
  [./eta]
    order = FIRST
    family = LAGRANGE
  [../]

  [./T]
    initial_condition = 473
  [../]
[]

[ICs]
  # UO2 = 0.0 and U4O9 = 0.25
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 25
    bubspac = 2.0
    radius = 2.0
    outvalue = 0.042
    invalue = 0.042
    block = 0
  [../]
  # UO2 = 0.0 and U4O9 = 1.0
  [./etaIC]
    type = MultiSmoothCircleIC
    variable = eta
    int_width = 0.1
    numbub = 25
    bubspac = 2.0
    radius = 2.0
    outvalue = 0
    invalue = 1.0
    block = 0
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
    value = 473
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-6
  [../]
[]

[Kernels]

  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]

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
    type = SplitCHWResAniso
    variable = w
    mob_name = M
  [../]
  [./anisotropy]
    type = CHInterfaceAniso
    variable = c
    mob_name = M
    kappa_name = kappa_c
  [../]

  [./time]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]
[]

[Materials]
  [./AHconsts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L kappa_eta'
    prop_values = '1 1'
  [../]
  [./CHconsts]
    type = GenericConstantMaterial
    prop_names  = 'kappa_c'
    prop_values = '2.0'
    block = 0
  [../]
  [./aniso]
    type = InterfaceOrientationMaterial
    block = 0
    c = c
  [../]
  [./mobility]
    type = ConstantAnisotropicMobility
    block = 0
    tensor = '.1  0  0
              0   0  0
              0   0  0'
    M_name = M
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
    function = '100*(c^2)'
    derivative_order = 2
    enable_jit = true
  [../]
  # Free energy of U4O9 domain
  [./free_energy_B]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fb
    args = 'c'
    function = '100*((0.25-c)^2)'
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
  nl_rel_tol = 1.0e-4

  start_time = 0.0
  num_steps = 3

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = .001 # Initial time step.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Adaptivity]
  marker = error_frac
  max_h_level = 3
  [./Indicators]
    [./eta_jump]
      type = GradientJumpIndicator
      variable = eta
      scale_by_flux_faces = true
    [../]
  [../]
  [./Markers]
    [./error_frac]
      type = ErrorFractionMarker
      coarsen = 0.01
      indicator = eta_jump
      refine = 0.6
    [../]
  [../]
[]

[Outputs]
  exodus = true
[]
