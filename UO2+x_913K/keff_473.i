#Thermal gradient script for last mesh in series

[Mesh]
  file = 913K_20_refine_out.e
[]

[Variables]
  [./T]
    initial_condition = 473
  [../]
[]

[AuxVariables]
  [./eta]
    order = FIRST
    family = LAGRANGE
    # For reading a solution
    # from an ExodusII file
    initial_from_file_var = eta
    initial_from_file_timestep = LATEST
  [../]
[]

[Kernels]
  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]
[]

[BCs]
  [./left] #Fix temperature on the left side
    type = DirichletBC
    variable = T
    boundary = left
    value = 473
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-7
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_b k_p2'
    constant_expressions = '1e-6 2.874 1.5'
    function = '(((1-eta)^2)*(k_b*length_scale))+(((eta)^2)*(k_p2*length_scale))'
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
    type = ThermalConductivity
    variable = T
    flux = 5e-7
    length_scale = 1e-06
    T_hot = 473
    dx = 50
    boundary = right
  [../]
[]

[Executioner]
  type = Steady
  l_max_its = 15
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre boomeramg 31 0.7'
  l_tol = 1e-04
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  csv = true
[]
