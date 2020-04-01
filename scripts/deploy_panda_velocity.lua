require "rttlib"
require "rttros"
require "utils"


rttlib.color=true

--If you set it to Info you will get more stuff printed from the driver
rtt.setLogLevel("Warning")

gs=rtt.provides()
tc=rtt.getTC()
if tc:getName() == "lua" then
  depl=tc:getPeer("Deployer")
elseif tc:getName() == "Deployer" then
  depl=tc
end
depl:import("rtt_ros")
ros:import("rtt_rospack")
depl:import("rtt_sensor_msgs")
depl:import("franka_panda_driver")
depl:import("rtt_motion_control_msgs")


ros = gs:provides("ros")
dir = rtt.provides("ros"):find("orocos_franka_panda") .. "/scripts/"

--Load the component generating the trajectory
depl:loadComponent("traj_gen", "OCL::LuaComponent")
traj_gen = depl:getPeer("traj_gen")
traj_gen:exec_file(dir .. "low_level_velocity_component.lua")
traj_gen:configure()

--Load the driver
depl:loadComponent("kin", "kinova_gen3")
kin = depl:getPeer("kin")

--Connect the ports
cp=rtt.Variable("ConnPolicy")
depl:connect("kin.sensor_joint_angles","traj_gen.measured_angles",cp )
depl:connect("kin.control_joint_velocities","traj_gen.desired_velocities",cp )

--Call configureHook() functions of both components
kin:configure()
traj_gen:configure()


--Set the control mode to low level position servoing (2)
kin:set_servoing_mode(1)

--Set the activity of both components running at 1 Khz (same frequency as the kinova robot control loop)
depl:setActivity("kin", 0.001, 0, rtt.globals.ORO_SCHED_OTHER) --Must run at 1 khz (0.001 ms), or else you will not get a smooth motion
depl:setActivity("traj_gen", 0.01, 0, rtt.globals.ORO_SCHED_OTHER)

--Start running the loop of both components.
kin:start()
traj_gen:start()

--This operation is used for telling the driver to start sending the setpoints to the robot
kin:start_sending_setpoints()
