[Mesh]
  # uniform_refine = 4
  type = FileMesh
  file = 15U3Si5_mesh_01.inp
[]


[BCs]
  [./left] #Fix temperature on the left side
    type = DirichletBC
    variable = T
    boundary = left
    value = 1673
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-6
  [../]
