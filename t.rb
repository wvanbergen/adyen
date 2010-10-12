framework File.expand_path("PS3Controller.framework")

@controller = PS3SixAxis.sixAixisControllerWithDelegate self

def connect
  puts "Connecting to the PS3 controller"
	@controller.connect(true)
end