[Mesh]
  type = ImageMesh
  dim = 2
  file =
[]

[Variables]
  [./u]
  [../]
[]

[Functions]
  [./image_func]
    # ImageFunction gets its file range parameters from ImageMesh,
    # when it is present.  This prevents duplicating information in
    # input files.
    type = ImageFunction
  [../]
[]

[ICs]
  [./u_ic]
    type = FunctionIC
    function = image_func
    variable = u
  [../]
[]

[Problem]
  type = FEProblem
  solve = false
[../]

[Executioner]
  type = Steady
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
[]
