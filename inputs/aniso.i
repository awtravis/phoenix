[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 25
  ny = 25
  ymax = 20
  xmax = 20
  uniform_refine = 2
[]

[ICs]
  [./etaIC]
    type = MultiSmoothCircleIC
    numbub = 40
    int_width = 0.1
    bubspac = 2.0
    radius = 1.0
    outvalue = 0 # UO2
    variable = eta
    invalue = 1 #U4O9
  [../]
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 40
    bubspac = 2.0
    radius = 1.0
    outvalue = 0.160
    invalue = 0.160
    block = 0
  [../]
[]

[Variables]
  [./T]
  [../]
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
  [./heat_conduction]
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

[Materials]
  [./AHconsts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L kappa_eta'
    prop_values = '1 1'
  [../]
  [./CHconsts]
    type = GenericConstantMaterial
    prop_names  = 'M kappa_c'
    prop_values = '1 1e-10'
    block = 0
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

  [./column]
    type = Micro
    block = 0
    phase = eta
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

[Postprocessors]
  [./k_eff]
    type = ThermalCond
    variable = T
    T_hot = 473
    flux = 5e-6
    dx = .02
    boundary = right
    length_scale = 1
  [../]
  [./right_T]
    type = SideAverageValue
    variable = T
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
  nl_rel_tol = 1.0e-4

  start_time = 0.0
  num_steps = 500

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
