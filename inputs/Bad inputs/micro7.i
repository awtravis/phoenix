[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 25
  ny = 25
  ymax = 10
  xmax = 10
  uniform_refine = 2
[]

[ICs]
  [./etaIC]
    type = MultiSmoothCircleIC
    numbub = 5
    int_width = 0.1
    bubspac = 1.0
    radius = 0.5
    outvalue = 0 # UO2
    variable = eta
    invalue = 1 #U4O9
  [../]
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 5
    bubspac = 1.0
    radius = 0.5
    outvalue = 0.063
    invalue = 0.063
    block = 0
  [../]
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

[BCs]
  [./Periodic]
    [./All]
      auto_direction = 'x y'
    [../]
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
    prop_values = '1'
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
    tensor = '1  0  0
              0  0  0
              0  0  0'
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
  execute_on = 'initial timestep_end'
  exodus = true
  csv = true
[]
