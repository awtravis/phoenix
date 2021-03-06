# Simple test microstructure for multiple U4O9 domains in a UO2 matrix
# Initial test condition with c = 0.10

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 25
  ny = 25
  nz = 0
  xmin = 0
  xmax = 20
  ymin = 0
  ymax = 20
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

[ICs]
  # UO2 = 0.0 and U4O9 = 0.25
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 25
    bubspac = 1.5
    radius = 1.0
    outvalue = 0.104
    invalue = 0.104
    block = 0
  [../]
[]

[BCs]
  [./Periodic]
    [./All]
      auto_direction = 'x y'
    [../]
  [../]
[]

[Kernels]
  [./c_res]
    type = SplitCHParsed
    variable = c
    f_name = F
    kappa_name = kappa_c
    w = w
  [../]
  [./w_res]
    type = SplitCHWResAniso
    variable = w
    mob_name = M
  [../]
  [./anisotropic]
    type = CHInterfaceAniso
    variable = c
    kappa_name = kappa_c
    mob_name = M
  [../]

  [./time]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]
[]

[Materials]
  [./consts2]
    type = GenericConstantMaterial
    prop_names  = 'kappa_c'
    prop_values = '.0001'
    block = 0
  [../]

  [./mobility]
    type = ConstantAnisotropicMobility
    M_name = M
    block = 0
    tensor = '.1 0 0
              0 0 0
              0 0 0'
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
    derivative_order = 2
    outputs = exodus
    output_properties = 'F dF/dc dF/deta d^2F/dc^2 d^2F/dcdeta d^2F/deta^2'
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
  num_steps = 300

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = .001 # Initial time step.  In this simulation it changes.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  exodus = true
[]
