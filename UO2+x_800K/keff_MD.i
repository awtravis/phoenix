#Thermal gradient script for last mesh in series

[Mesh]
  file = 913K_20_refine_out.e
[]

[Variables]
  [./T]
    initial_condition = 298
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
  [./c]
    order = FIRST
    family = LAGRANGE
    # For reading a solution
    # from an ExodusII file
    initial_from_file_var = c
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
    value = 298
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-7
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here
    type = ParsedMaterial
    block = 0
    args = 'c T eta'
    constant_names = 'A
                      B
                      D
                      k_U4O9
                      length_scale'
    constant_expressions = '0.0311
                            0.000208
                            5.92666667
                            1.5
                            1e-6'
    function = 'k_UO2x:=(1/(A+(B*T)+(D*c))); (((1-eta)^2)*(k_UO2x*length_scale))+(((eta)^2)*(k_U4O9*length_scale))'
    outputs = exodus
    f_name = thermal_conductivity
  [../]
[]

[Postprocessors]
  [./right_T]
    type = SideAverageValue
    variable = T
    boundary = right
  [../]
  [./k_x_direct] #Effective thermal conductivity from direct method
    type = ThermalConductivity
    variable = T
    flux = 5e-7
    length_scale = 1e-06
    T_hot = 298
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
  l_tol = 1e-4
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  csv = true
[]
