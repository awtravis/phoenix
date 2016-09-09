#
# KKS toy problem in the split form
#

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 15
  ny = 15
  nz = 0
  xmin = -2.5
  xmax = 2.5
  ymin = -2.5
  ymax = 2.5
  zmin = 0
  zmax = 0
  elem_type = QUAD4
[]

[AuxVariables]
  [./Fglobal]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[Variables]
  # order parameter
  [./eta]
    order = FIRST
    family = LAGRANGE
  [../]

  # hydrogen concentration
  [./c]
    order = FIRST
    family = LAGRANGE
  [../]

  # chemical potential
  [./w]
    order = FIRST
    family = LAGRANGE
  [../]

  # hydrogen phase concentration (matrix)
  [./cm]
    order = FIRST
    family = LAGRANGE
    initial_condition = 0.143
  [../]
  # hydrogen phase concentration (delta phase)
  [./cd]
    order = FIRST
    family = LAGRANGE
    initial_condition = 0.143
  [../]
[]

[ICs]
  [./eta]
    variable = eta
    type = SmoothCircleIC
    x1 = 0.0
    y1 = 0.0
    radius = 1.5
    invalue = 1
    outvalue = 0
    int_width = 0.75
  [../]
  [./c]
    variable = c
    type = SmoothCircleIC
    x1 = 0.0
    y1 = 0.0
    radius = 1.5
    invalue = 0.143
    outvalue = 0.143
    int_width = 0.75
  [../]
[]


[BCs]
  [./Periodic]
    [./all]
      variable = 'eta w c cm cd'
      auto_direction = 'x y'
    [../]
  [../]
[]

[Materials]
  # Free energy of the matrix
  [./fm]
    type = DerivativeParsedMaterial
    f_name = fm
    args = 'cm'
    constant_names =       'T
                            R
                            G_gas_O
                            G_U4_O2_Va
                            G_U4_O2_O2
                            G_U5_O2_Va
                            G_U5_O2_O2
                            L_U4_U5'
    constant_expressions = '900
                            8.3144598
                            ((-3480.870)-(25.503038*T)-(11.136*T*log(T))-(5.09888*(10^(-3)*(T^(2))))+(0.661846*(10^(-6))*(T^(3)))-(38365.0*(T^(-1))))
                            ((-1118940.2)+(554.00559*T)-(93.268*T*log(T))+(1.01704354*(10^(-2))*(T^(2)))-(2.03335671*(10^(-6))*(T^(3)))+(1091073.7*(T^(-1))))
                            (G_U4_O2_Va+G_gas_O)
                            ((G_U4_O2_Va)-(58351.62)+(39.67611*T)+(0.69315*R*T))
                            (G_U5_O2_Va+G_gas_O)
                            ((-124936.9)-(21.6838*T))'
    function = '((((1-(2*cm))*(1-cm)*G_U4_O2_Va) + ((1-(2*cm))*(cm)*G_U4_O2_O2) + ((2*cm)*(1-cm)*G_U5_O2_Va) + ((2*cm)*(cm)*G_U5_O2_O2)) + (R*T*((((1-(2*cm))*log((1-(2*cm))))+(((2*cm)*plog(2*cm,2.718)))) + (((cm)*plog(cm,2.718))+((1-cm)*log(1-cm))))) + ((1-(2*cm))*(2*cm)*L_U4_U5))'
    derivative_order = 2
    enable_jit = true
  [../]

  # Free energy of the delta phase
  [./fd]
    type = DerivativeParsedMaterial
    f_name = fd
    args = 'cd'
    constant_names = 'T
                      R
                      G_U4O9'
    constant_expressions = '900
                            8.3144598
                            ((-4621329.3)+(1786.83274*T)-(311.20912*T*log(T))-(0.0311301013*T^(2))+(1741269.49*T^(-1)))'
    function = '((((0.25-cd)^2) + ((G_U4O9)-(R*T*(((0.5)*log(0.5))+((0.5)*log(0.5))))))/4)'
    derivative_order = 2
    enable_jit = true
  [../]

  # h(eta)
  [./h_eta]
    type = SwitchingFunctionMaterial
    h_order = HIGH
    eta = eta
  [../]

  # g(eta)
  [./g_eta]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta
  [../]

  # constant properties
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'M   L   kappa'
    prop_values = '0.7 0.7 0.4  '
  [../]
[]

[Kernels]
  # full transient
  active = 'PhaseConc ChemPotVacancies CHBulk ACBulkF ACBulkC ACInterface dcdt detadt ckernel'

  # enforce c = (1-h(eta))*cm + h(eta)*cd
  [./PhaseConc]
    type = KKSPhaseConcentration
    ca       = cm
    variable = cd
    c        = c
    eta      = eta
  [../]

  # enforce pointwise equality of chemical potentials
  [./ChemPotVacancies]
    type = KKSPhaseChemicalPotential
    variable = cm
    cb       = cd
    fa_name  = fm
    fb_name  = fd
  [../]

  #
  # Cahn-Hilliard Equation
  #
  [./CHBulk]
    type = KKSSplitCHCRes
    variable = c
    ca       = cm
    cb       = cd
    fa_name  = fm
    fb_name  = fd
    w        = w
  [../]

  [./dcdt]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]
  [./ckernel]
    type = SplitCHWRes
    mob_name = M
    variable = w
  [../]

  #
  # Allen-Cahn Equation
  #
  [./ACBulkF]
    type = KKSACBulkF
    variable = eta
    fa_name  = fm
    fb_name  = fd
    args     = 'cm cd'
    w        = 0.4
  [../]
  [./ACBulkC]
    type = KKSACBulkC
    variable = eta
    ca       = cm
    cb       = cd
    fa_name  = fm
    fb_name  = fd
  [../]
  [./ACInterface]
    type = ACInterface
    variable = eta
    kappa_name = kappa
  [../]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
[]

[AuxKernels]
  [./GlobalFreeEnergy]
    variable = Fglobal
    type = KKSGlobalFreeEnergy
    fa_name = fm
    fb_name = fd
    w = 0.4
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_factor_shift_type'
  petsc_options_value = 'nonzero'

  l_max_its = 100
  l_tol = 1e-10

  nl_max_its = 100
  nl_rel_tol = 1e-10

  start_time = 0
  num_steps = 500

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = 1e-10 # Initial time step.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

#
# Precondition using handcoded off-diagonal terms
#
[Preconditioning]
  [./full]
    type = SMP
    full = true
  [../]
[]


[Outputs]
  exodus = true
[]
