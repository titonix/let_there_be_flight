public class FlightModeDrone extends FlightMode {
  public static func Create(component: ref<FlightComponent>) -> ref<FlightModeDrone> {
    let self = new FlightModeDrone();
    self.Initialize(component);
    return self;
  }

  public func GetDescription() -> String = "Drone";

  public func Update(timeDelta: Float) -> Void {
      let velocityDamp: Vector4 = this.component.stats.d_localVelocity * this.component.brake * FlightSettings.GetFloat(n"brakeFactor") * this.component.stats.s_brakingFrictionFactor;   
      let angularDamp: Vector4 = this.component.stats.d_angularVelocity * this.component.brake * FlightSettings.GetFloat(n"angularBrakeFactor") * this.component.stats.s_brakingFrictionFactor;

      this.force = new Vector4(0.0, 0.0, 0.0, 0.0);
      // lift
      this.force += FlightUtils.Up() * this.component.lift * FlightSettings.GetFloat(n"liftFactorDrone");
      // surge
      this.force += FlightUtils.Forward() * this.component.surge * FlightSettings.GetFloat(n"surgeFactor");
      // directional brake
      this.force -= velocityDamp;

      this.torque = new Vector4(0.0, 0.0, 0.0, 0.0);
      // pitch correction
      this.torque.X = -(this.component.pitch * FlightSettings.GetFloat(n"pitchFactorDrone") + angularDamp.X);
      // roll correction
      this.torque.Y = (this.component.roll * FlightSettings.GetFloat(n"rollFactorDrone") - angularDamp.Y);
      // yaw correction
      this.torque.Z = -(this.component.yaw * FlightSettings.GetFloat(n"yawFactorDrone") + angularDamp.Z);
  }
}