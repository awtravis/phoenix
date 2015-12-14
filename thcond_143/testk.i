[Mesh]#Comment
  file = micro_143_out.e
[] # Mesh

[Functions]
  [./k_func]
    type = PiecewiseLinear
    x = '0 1 2'
    y = '9.731   8.469   6.9'
  [../]

  [./t_func]
    type = PiecewiseLinear
    x = '0   1   2'
    y = '298 373 473'
  [../]
[] # Functions

[Variables]

  [./temp]
    order = FIRST
    family = LAGRANGE
    initial_condition = 298
  [../]
[] # Variables

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

  [./heat_r]
    type = HeatConduction
    variable = temp
  [../]


[] # Kernels

[BCs]

  [./temps_function]
    type = FunctionPresetBC
    variable = temp
    boundary = right
    function = t_func
  [../]

  [./flux_in]
    type = NeumannBC
    variable = temp
    boundary = left
    value = 10
  [../]

[] # BCs

[Materials]

  [./heat]
    type = HeatConductionMaterial
    block = 0
    temp = temp
    thermal_conductivity_temperature_function = k_func
  [../]

[] # Materials

[Postprocessors]
  [./right_T]
    type = SideAverageValue
    variable = temp
    boundary = right
  [../]
  [./k_x_direct] #Effective thermal conductivity from direct method
    # This value is lower than the AEH value because it is impacted by second phase
    # on the right boundary
    type = ThermalCond
    variable = temp
    flux = 5e-6
    length_scale = 1e-06
    T_hot = 298
    dx = 50
    boundary = right
  [../]
[]

[Executioner]

  type = Transient


  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'



  petsc_options_iname = '-pc_type -ksp_gmres_restart'
  petsc_options_value = 'lu       101'


  line_search = 'none'


  l_max_its = 100
  l_tol = 8e-3

  nl_max_its = 15
  nl_rel_tol = 1e-4
  nl_abs_tol = 1e-10

  start_time = 0.0
  dt = 1
  end_time = 2
  num_steps = 2


[] # Executioner

[Outputs]
  file_base = out
  exodus = true
[] # Outputs
