#Thermal gradient script for last mesh in series

[Mesh]
  file = micro_143_out.e
  block = 0
[]

[Variables]
  [./T]
    initial_condition = 473
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 473
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 473
    scaling = 1.0e4  #Scales residual to improve convergence
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
  [./heat_x] #All other kernels are for AEH approach to calculate thermal cond.
    type = HeatConduction
    variable = Tx_AEH
  [../]
  [./heat_rhs_x]
    type = HomogenizationHeatConduction
    variable = Tx_AEH
    component = 0
  [../]
  [./heat_y]
    type = HeatConduction
    variable = Ty_AEH
  [../]
  [./heat_rhs_y]
    type = HomogenizationHeatConduction
    variable = Ty_AEH
    component = 1
  [../]
[]

[BCs]
  [./Periodic]
    [./all]
      auto_direction = 'x y'
      variable = 'Tx_AEH Ty_AEH'
    [../]
  [../]
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
    value = 5e-6
  [../]
  [./fix_x] #Fix Tx_AEH at a single point
    type = DirichletBC
    variable = Tx_AEH
    value = 473
    boundary = left
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 473
    boundary = left
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_b k_p2 k_int'
    constant_expressions = '1e-6 6.9 1.5 0.1'
    function = 'sk_b:= length_scale*k_b; sk_p2:= length_scale*k_p2; sk_int:= k_int*length_scale; if(eta>0.1,if(eta>0.90,sk_p2,sk_int),sk_b)'
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
    type = ThermalCond
    variable = T
    flux = 5e-6
    length_scale = 1e-06
    T_hot = 473
    dx = 50
    boundary = right
  [../]
  [./k_x_AEH] #Effective thermal conductivity in x-direction from AEH
    type = HomogenizedThermalConductivity
    variable = Tx_AEH
    temp_x = Tx_AEH
    temp_y = Ty_AEH
    component = 0
    scale_factor = 1e6 #Scale due to length scale of problem
  [../]
  [./k_y_AEH] #Effective thermal conductivity in x-direction from AEH
    type = HomogenizedThermalConductivity
    variable = Ty_AEH
    temp_x = Tx_AEH
    temp_y = Ty_AEH
    component = 1
    scale_factor = 1e6 #Scale due to length scale of problem
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    off_diag_row = 'Tx_AEH Ty_AEH'
    off_diag_column = 'Ty_AEH Tx_AEH'
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
