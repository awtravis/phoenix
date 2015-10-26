#
# KKS toy problem in the non-split form
#

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
  zmin = 0
  zmax = 0
  elem_type = QUAD4
[]

[Variables]
  # order parameter
  [./eta]
    order = THIRD
    family = HERMITE
  [../]

  # hydrogen concentration
  [./c]
    order = THIRD
    family = HERMITE
  [../]

  # hydrogen phase concentration (matrix)
  [./cm]
    order = THIRD
    family = HERMITE
    initial_condition = 0.0
  [../]
  # hydrogen phase concentration (delta phase)
  [./cd]
    order = THIRD
    family = HERMITE
    initial_condition = 0.0
  [../]
[]

[ICs]
  [./eta]
    variable = eta
    type = MultiSmoothCircleIC
    int_width = 0.05
    numbub = 4
    bubspac = 1.5
    radius = 0.5
    outvalue = 0
    invalue = 1
    block = 0
  [../]
  [./c]
    variable = c
    type = MultiSmoothCircleIC
    int_width = 0.3
    numbub = 4
    bubspac = 1.5
    radius = 0.5
    outvalue = 0.4
    invalue = 0.6
    block = 0
  [../]
[]

[BCs]
  [./Periodic]
    [./all]
      variable = 'eta c cm cd'
      auto_direction = 'x y'
    [../]
  [../]
[]

[Materials]
  # Free energy of the matrix
  [./fm]
    type = DerivativeParsedMaterial
    block = 0
    f_name = fm
    args = 'cm'
    function = '(0.1-cm)^2'
    outputs = oversampling
  [../]

  # Free energy of the delta phase
  [./fd]
    type = DerivativeParsedMaterial
    block = 0
    f_name = fd
    args = 'cd'
    function = '(0.9-cd)^2'
    outputs = oversampling
  [../]

  # h(eta)
  [./h_eta]
    type = SwitchingFunctionMaterial
    block = 0
    h_order = HIGH
    eta = eta
    outputs = oversampling
  [../]

  # g(eta)
  [./g_eta]
    type = BarrierFunctionMaterial
    block = 0
    g_order = SIMPLE
    eta = eta
    outputs = oversampling
  [../]

  # constant properties
  [./constants]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'L   '
    prop_values = '0.7 '
  [../]
[]

[Kernels]
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
    type = KKSCHBulk
    variable = c
    ca       = cm
    cb       = cd
    fa_name  = fm
    fb_name  = fd
    mob_name = 0.7
  [../]
  [./dcdt]
    type = TimeDerivative
    variable = c
  [../]

  #
  # Allen-Cahn Equation
  #
  [./ACBulkF]
    type = KKSACBulkF
    variable = eta
    fa_name  = fm
    fb_name  = fd
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
    kappa_name = 0.4
  [../]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_factor_shift_type'
  petsc_options_value = 'nonzero'

  l_max_its = 100
  nl_max_its = 100
  nl_rel_tol = 1e-4

  num_steps = 10

  dt = 0.01
  dtmin = 0.01
[]

#
# This still needs finite difference preconditioning as the
# handcoded jacobians are not complete. Check out the split
# solve, which works with SMP preconditioning.
#
[Preconditioning]
  [./mydebug]
    type = FDP
    full = true
  [../]
[]

[Outputs]
  file_base = kks_example
  [./oversampling]
    type = Exodus
    refinements = 3
  [../]
[]
