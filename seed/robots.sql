  -- seed: 机器人型号。可重复执行。
  USE drl_train;

  INSERT INTO robots
    (robot_id, display_name, dof_count, mass_kg, urdf_sha256, urdf_path, notes)
  VALUES
    ('d1_edu_12dof', '智元 D1 edu', 12, 15.1860,
     'c7d5ad671cda322bcb5c949ae6c11acbb937eb2113a5feaa62b025c1e383e2c4',
     '~/self-AGI/urdf/edu_description/urdf/edu.urdf',
     '训狗 D1 项目主力。总质量与 robot_lab 官方 D1 配置一致（15.186 kg）。')
    AS new
  ON DUPLICATE KEY UPDATE
    display_name = new.display_name,
    dof_count    = new.dof_count,
    mass_kg      = new.mass_kg,
    urdf_sha256  = new.urdf_sha256,
    urdf_path    = new.urdf_path,
    notes        = new.notes;

