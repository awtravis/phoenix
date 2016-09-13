[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 100
  ny = 100
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
    numbub = 100
    int_width = 0.25
    bubspac = 2
    radius = 0.5
    outvalue = 0 # UO2
    variable = eta
    invalue = 1 #U4O9
    block = 0
  [../]
  [./concentrationIC]
    type = MultiSmoothCircleIC
    variable = c
    int_width = 0.25
    numbub = 100
    bubspac = 2
    radius = 0.5
    outvalue = 0.230
    invalue = 0.230
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
    h_order = HIGH
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
  l_tol = 1.0e-12

  nl_max_its = 10
  nl_rel_tol = 1.0e-12

  start_time = 0.0
  num_steps = 2000

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = 1e-10 # Initial time step.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  execute_on = 'initial timestep_end'
  exodus = true
[]
