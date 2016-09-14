[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 50
  ny = 50
  xmin = 0
  ymin = 0
  xmax = 50
  ymax = 50
  elem_type = QUAD4
[]

[Variables]
  [./eta]
    order = FIRST
    family = LAGRANGE
  [../]
  [./c]
    order = FIRST
    family = LAGRANGE
  [../]
  [./w]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[ICs]
  [./etaIC]
    type = MultiSmoothCircleIC
    variable = eta
    numbub = 200
    int_width = 0.1
    bubspac = 2.0
    radius = 0.5
    outvalue = 0 # UO2
    invalue = 1 #U4O9
    block = 0
  [../]
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 200
    bubspac = 2.0
    radius = 0.5
    outvalue = 0.20
    invalue = 0.20
    block = 0
  [../]
[]

[Kernels]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
  [./anisoACinterface1]
    type = ACInterfaceKobayashi1
    variable = eta
    mob_name = L
  [../]
  [./anisoACinterface2]
    type = ACInterfaceKobayashi2
    variable = eta
    mob_name = L
  [../]
  [./AllenCahn]
    type = AllenCahn
    variable = eta
    args = c
    mob_name = L
    f_name = F
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
[]

[BCs]
  [./Periodic]
    [./All]
      auto_direction = 'x y'
    [../]
  [../]
[]

[Materials]
  # Material properties for descirbing anisotropy of the system
  [./Consts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L M kappa_c'
    prop_values = '1 1 1'
  [../]
  [./aniso]
    type = WidmanstattenMaterial
    block = 0
    op = eta
  [../]

  # Free energy of UO2 matrix
  [./free_energy_A]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fa
    args = 'c'
    constant_names = 'T'
    constant_expressions = '913'
    function = '(((c-((T-231.78)/4672.9))^2)*5)'
    derivative_order = 2
    enable_jit = true
  [../]
  # Free energy of U4O9 domain
  [./free_energy_B]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fb
    args = 'c'
    function = '(((c-0.25)^2)*5)'
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

  [./barrier]
    type = BarrierFunctionMaterial
    block = 0
    eta = eta
    g_order = SIMPLE
  [../]

  [./switching]
    type = SwitchingFunctionMaterial
    block = 0
    function_name = h
    eta = eta
    h_order = SIMPLE
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
  num_steps = 1000

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = 1e-4 # Initial time step.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]

  [./Adaptivity]
    initial_adaptivity = 3 # Number of times mesh is adapted to initial condition
    refine_fraction = 0.7 # Fraction of high error that will be refined
    coarsen_fraction = 0.1 # Fraction of low error that will coarsened
    max_h_level = 3 # Max number of refinements used, starting from initial mesh (before uniform refinement)
  [../]
[]

[Outputs]
  execute_on = 'initial timestep_end'
  exodus = true
[]
