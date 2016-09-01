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
[]

[ICs]
  # UO2 = 0.0 and U4O9 = 0.25
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.1
    numbub = 25
    bubspac = 1.5
    radius = 1.0
    outvalue = 0.143
    invalue = 0.143
    block = 0
  [../]
  # UO2 = 0.0 and U4O9 = 1.0
  [./etaIC]
    type = MultiSmoothCircleIC
    variable = eta
    int_width = 0.1
    numbub = 25
    bubspac = 1.5
    radius = 1.0
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
[]

[Kernels]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
  [./ACBulk]
    type = AllenCahn
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
  [./consts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L kappa_eta'
    prop_values = '1 1'
  [../]
  [./consts2]
    type = GenericConstantMaterial
    prop_names  = 'kappa_c'
    prop_values = '1'
    block = 0
  [../]

  [./mobility]
    type = ConstantAnisotropicMobility
    M_name = M
    block = 0
    tensor = '1 0 0
              0 1 0
              0 0 0'
  [../]

  [./switching]
    type = SwitchingFunctionMaterial
    block = 0
    eta = eta
    h_order = SIMPLE
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
    # 1) Temperature in Kelvin (K)
    # 2) R is gas constant in J/mol/K
    # 3) y_U4 = site fraction of U4+ as a function of oxygen concentration
    # 4) y_U5 = site fraction of U5+ as a function of oxygen concentration
    # 5) y_Va = site fraction of Vacancies on the interstitial site
    # 6) y_O2 = site fraction of oxygen ion on the interstitial site
    # 7) G_gas_0 = Gibss free energy of 1/2 mole of gaseous O2 (A.T. Dinsdale SGTE 1991)
    # 8) G_U4_O2_Va = G^UO2+x _U4+_O2-_Va
    # 9) G_U4_O2_O2 = G^UO2+x _U4+_O2-_O2-
    # 10) G_U5_O2_Va = G^UO2+x _U5+_O2-_Va
    # 10) G_U5_O2_O2 = G^UO2+x _U5+_O2-_O2-
    # 11) L_U4_U5 = free energy term for U4+ and U5+
    # 12) G_exc_UO2 = excess Gibbs energy for UO2+x
    constant_names =       'T
                            R
                            G_gas_O
                            G_U4_O2_Va
                            G_U4_O2_O2
                            G_U5_O2_Va
                            G_U5_O2_O2
                            L_U4_U5'
    constant_expressions = '913
                            8.3144598
                            ((-3480.870)-(25.503038*T)-(11.136*T*log(T))-(5.09888*(10^(-3)*(T^(2))))+(0.661846*(10^(-6))*(T^(3)))-(38365*(T^(-1))))
                            ((-1118940.2)+(554.00559*T)-(93.268*T*log(T))+(1.01704354*(10^(-2))*(T^(2)))-(2.03335671*(10^(-6))*(T^(3)))+(1091073.7*(T^(-1))))
                            (G_U4_O2_Va+G_gas_O)
                            ((G_U4_O2_Va)-(58351.62)+(39.67611*T)+(0.69315*R*T))
                            (G_U5_O2_Va+G_gas_O)
                            ((-124936.9)-(21.6838*T))'
    function = '(((1-(2*c))*(1-c)*-G_U4_O2_Va) + ((1-(2*c))*(c)*G_U4_O2_O2) + ((2*c)*(1-c)*G_U5_O2_Va) + ((2*c)*(c)*-G_U5_O2_O2) + (R*T*(((1-(2*c))*plog((1-(2*c)),2.718))+(((2*c)*plog(2*c,2.718))))) + (R*T*(((c)*plog(c,2.718))+((1-c)*plog(1-c,2.718)))) + ((1-(2*c))*(2*c)*L_U4_U5))'
    derivative_order = 2
    enable_jit = true
  [../]
  # Free energy of U4O9 domain
  [./free_energy_B]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fb
    args = 'c'
    constant_names = 'T
                      R
                      G_U4O9'
    constant_expressions = '913
                            8.3144598
                            ((-4621329.3)+(1786.83274*T)-(311.20912*T*log(T))-(0.0311301013*T^(2))+(1741269.49*T^(-1)))'
    function = '(((-(0.25-c)^2)*(G_U4O9)) + (R*T*(((0.5)*log(0.5))+((0.5)*log(0.5)))))'
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
  num_steps = 1000

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = 1e-8 # Initial time step.  In this simulation it changes.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  exodus = true
[]
