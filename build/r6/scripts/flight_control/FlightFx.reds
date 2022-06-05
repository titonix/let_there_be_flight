public class FlightFx {
  private let sys: ref<FlightSystem>;
  public let component: ref<FlightComponent>;

  public let f_fx: ref<FxInstance>;
  public let b_fx: ref<FxInstance>;
  public let fl_fx: ref<FxInstance>;
  public let flb_fx: ref<FxInstance>;
  public let fr_fx: ref<FxInstance>;
  public let frb_fx: ref<FxInstance>;
  public let bl_fx: ref<FxInstance>;
  public let br_fx: ref<FxInstance>;

  public let bl_retroFx: ref<FxInstance>;
  public let br_retroFx: ref<FxInstance>;
  public let fl_retroFx: ref<FxInstance>;
  public let fr_retroFx: ref<FxInstance>;

  public let resource: FxResource;
  public let retroResource: FxResource;

  let f_fx_wt: WorldTransform;
  let b_fx_wt: WorldTransform;
  let bl_fx_wt: WorldTransform;
  let br_fx_wt: WorldTransform;
  let fl_fx_wt: WorldTransform;
  let fr_fx_wt: WorldTransform;
  let flb_fx_wt: WorldTransform;
  let frb_fx_wt: WorldTransform;

  public let fl_thruster: ref<IPlacedComponent>;
  public let fr_thruster: ref<IPlacedComponent>;
  public let bl_thruster: ref<IPlacedComponent>;
  public let br_thruster: ref<IPlacedComponent>;

  public let chassis: ref<IComponent>;

  public let fc: array<ref<IComponent>>;
  public let bc: array<ref<IComponent>>;
  public let blc: array<ref<IComponent>>;
  public let brc: array<ref<IComponent>>;
  public let flc: array<ref<IComponent>>;
  public let flbc: array<ref<IComponent>>;
  public let frc: array<ref<IComponent>>;
  public let frbc: array<ref<IComponent>>;
  public let ui: ref<IPlacedComponent>;
  public let ui_info: ref<IPlacedComponent>;

  public static func Create(component: ref<FlightComponent>) -> ref<FlightFx> {
    return new FlightFx().Initialize(component);
  }

  public func Initialize(component: ref<FlightComponent>) -> ref<FlightFx> {
    this.sys = component.sys;
    this.component = component;
    this.resource = Cast<FxResource>(r"user\\jackhumbert\\effects\\ion_thruster.effect");
    this.retroResource = Cast<FxResource>(r"user\\jackhumbert\\effects\\retro_thruster.effect");

    let vehicleComponent = this.component.GetVehicle().GetVehicleComponent();

    this.fl_thruster = vehicleComponent.FindComponentByName(n"ThrusterFL") as IPlacedComponent;
    this.fl_thruster.Toggle(false);
    this.fl_thruster.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(0.0, 180.0, 180.0)));

    this.fr_thruster = vehicleComponent.FindComponentByName(n"ThrusterFR") as IPlacedComponent;
    this.fr_thruster.Toggle(false);
    this.fr_thruster.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, -180.0)));

    this.bl_thruster = vehicleComponent.FindComponentByName(n"ThrusterBL") as IPlacedComponent;
    this.bl_thruster.Toggle(false);
    this.bl_thruster.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(0.0, 180.0, 180.0)));

    this.br_thruster = vehicleComponent.FindComponentByName(n"ThrusterBR") as IPlacedComponent;
    this.br_thruster.Toggle(false);
    this.br_thruster.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, -180.0)));

    return this;
  }

  public func HasFWheel() -> Bool {
    return ArraySize(this.fc) > 0;
  }
  
  public func HasBWheel() -> Bool {
    return ArraySize(this.bc) > 0;
  }

  public func HasFLWheel() -> Bool {
    return ArraySize(this.flc) > 0;
  }
  
  public func HasFLBWheel() -> Bool {
    return ArraySize(this.flbc) > 0;
  }
  
  public func HasFRWheel() -> Bool {
    return ArraySize(this.frc) > 0;
  }
  
  public func HasFRBWheel() -> Bool {
    return ArraySize(this.frbc) > 0;
  }
  
  public func HasBLWheel() -> Bool {
    return ArraySize(this.blc) > 0;
  }
  
  public func HasBRWheel() -> Bool {
    return ArraySize(this.brc) > 0;
  }

  public func Start() {
    this.fc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front");
    if ArraySize(this.fc) == 0 {
      this.fc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front_rot_set");
    }
    this.bc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_back");
    if ArraySize(this.bc) == 0 {
      this.bc = this.component.GetVehicle().GetComponentsUsingSlot(n"axle_back_wheel");
    }
    this.blc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_back_left");
    this.brc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_back_right");
    this.flc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front_left");
    this.flbc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front_left_b");
    this.frc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front_right");
    this.frbc = this.component.GetVehicle().GetComponentsUsingSlot(n"wheel_front_right_b");

    
    let vehicleComponent = this.component.GetVehicle().GetVehicleComponent();
    this.chassis = vehicleComponent.FindComponentByName(n"chassis") as IComponent;
    if !IsDefined(this.chassis) {
      this.chassis = vehicleComponent.FindComponentByName(n"chasis") as IComponent;
    }

    this.ui = vehicleComponent.FindComponentByName(n"flight_screen") as IPlacedComponent;
    this.ui_info = vehicleComponent.FindComponentByName(n"flight_screen_info") as IPlacedComponent;

    this.HideWheelComponents();

    let effectTransform: WorldTransform;
    WorldTransform.SetPosition(effectTransform, this.component.stats.d_position);
    let wt = new WorldTransform();
    WorldTransform.SetPosition(wt, new Vector4(0.0, 0.0, 0.0, 0.0));
    let chassisOffset = (vehicleComponent.FindComponentByName(n"Chassis") as vehicleChassisComponent).GetLocalPosition();
    let vehicleSlots = this.component.GetVehicle().GetVehicleComponent().FindComponentByName(n"vehicle_slots") as SlotComponent;
    let vwt = Matrix.GetInverted(this.component.GetVehicle().GetLocalToWorld());
    if this.HasFWheel() {
      this.f_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.f_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      vehicleSlots.GetSlotTransform(n"wheel_front", this.f_fx_wt);
      this.component.fl_tire.SetLocalPosition(-chassisOffset + WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.f_fx_wt)) * vwt);
      this.f_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"WheelAudioEmitterFront", wt);
    }
    if this.HasBWheel() {
      this.b_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.b_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      vehicleSlots.GetSlotTransform(n"wheel_back", this.b_fx_wt);
      this.component.bl_tire.SetLocalPosition(-chassisOffset + WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.b_fx_wt)) * vwt);
      this.b_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"WheelAudioEmitterBack", wt);
    }
    if this.HasBLWheel() {
      this.bl_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.bl_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      this.bl_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"ThrusterBL", wt);
      this.bl_thruster.Toggle(true);

      let wt_retro: WorldTransform;
      let p = this.component.bl_tire.GetLocalPosition();
      p.Z = 0.0;
      WorldTransform.SetPosition(wt_retro, p);
      WorldTransform.SetOrientation(wt_retro, EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, 90.0)));
      this.bl_retroFx =  GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.retroResource, effectTransform);
      this.bl_retroFx.AttachToSlot(this.component.GetVehicle(), entAttachmentTarget.Transform, n"Base", wt_retro);
    }
    if this.HasBRWheel() {
      this.br_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.br_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      this.br_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"ThrusterBR", wt);
      this.br_thruster.Toggle(true);

      let wt_retro: WorldTransform;
      let p = this.component.br_tire.GetLocalPosition();
      p.Z = 0.0;
      WorldTransform.SetPosition(wt_retro, p);
      WorldTransform.SetOrientation(wt_retro, EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, -90.0)));
      this.br_retroFx =  GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.retroResource, effectTransform);
      this.br_retroFx.AttachToSlot(this.component.GetVehicle(), entAttachmentTarget.Transform, n"Base", wt_retro);
    }
    if this.HasFLWheel() {
      this.fl_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.fl_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      this.fl_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"ThrusterFL", wt);
      this.fl_thruster.Toggle(true);

      let wt_retro: WorldTransform;
      let p = this.component.fl_tire.GetLocalPosition();
      p.Z = 0.0;
      WorldTransform.SetPosition(wt_retro, p);
      WorldTransform.SetOrientation(wt_retro, EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, 90.0)));
      this.fl_retroFx =  GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.retroResource, effectTransform);
      this.fl_retroFx.AttachToSlot(this.component.GetVehicle(), entAttachmentTarget.Transform, n"Base", wt_retro);
    }
    if this.HasFRWheel() {
      this.fr_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.fr_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      this.fr_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"ThrusterFR", wt);
      this.fr_thruster.Toggle(true);

      let wt_retro: WorldTransform;
      let p = this.component.fr_tire.GetLocalPosition();
      p.Z = 0.0;
      WorldTransform.SetPosition(wt_retro, p);
      WorldTransform.SetOrientation(wt_retro, EulerAngles.ToQuat(new EulerAngles(0.0, 0.0, -90.0)));
      this.fr_retroFx =  GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.retroResource, effectTransform);
      this.fr_retroFx.AttachToSlot(this.component.GetVehicle(), entAttachmentTarget.Transform, n"Base", wt_retro);
    }
    if this.HasFLBWheel() {
      this.flb_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.flb_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      vehicleSlots.GetSlotTransform(n"wheel_front_left_b", this.flb_fx_wt);
      this.component.hood.SetLocalPosition(-chassisOffset + WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.flb_fx_wt)) * vwt);
      this.flb_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"VehicleHoodEmitter", wt);
    }
    if this.HasFRBWheel() {
      this.frb_fx = GameInstance.GetFxSystem(this.component.GetVehicle().GetGame()).SpawnEffect(this.resource, effectTransform);
      this.frb_fx.SetBlackboardValue(n"thruster_amount", 0.0);
      vehicleSlots.GetSlotTransform(n"wheel_front_right_b", this.frb_fx_wt);
      this.component.trunk.SetLocalPosition(-chassisOffset + WorldPosition.ToVector4(WorldTransform.GetWorldPosition(this.frb_fx_wt)) * vwt);
      this.frb_fx.AttachToComponent(this.component.GetVehicle(), entAttachmentTarget.Transform, n"VehicleTrunkEmitter", wt);
    }
  }

  public func Stop() {
    if IsDefined(this.f_fx) {
      this.f_fx.BreakLoop();
    }
    if IsDefined(this.b_fx) {
      this.b_fx.BreakLoop();
    }
    if IsDefined(this.bl_fx) {
      this.bl_fx.BreakLoop();
      this.bl_thruster.Toggle(false);
    }
    if IsDefined(this.br_fx) {
      this.br_fx.BreakLoop();
      this.br_thruster.Toggle(false);
    }
    if IsDefined(this.fl_fx) {
      this.fl_fx.BreakLoop();
      this.fl_thruster.Toggle(false);
    }
    if IsDefined(this.fr_fx) {
      this.fr_fx.BreakLoop();
      this.fr_thruster.Toggle(false);
    }
    if IsDefined(this.flb_fx) {
      this.flb_fx.BreakLoop();
    }
    if IsDefined(this.frb_fx) {
      this.frb_fx.BreakLoop();
    }

    if IsDefined(this.bl_retroFx) {
      this.bl_retroFx.BreakLoop();
    }
    if IsDefined(this.br_retroFx) {
      this.br_retroFx.BreakLoop();
    }
    if IsDefined(this.fl_retroFx) {
      this.fl_retroFx.BreakLoop();
    }
    if IsDefined(this.fr_retroFx) {
      this.fr_retroFx.BreakLoop();
    }

    this.ShowWheelComponents();
  }

  public func Update(force: Vector4, torque: Vector4) {
    // would be nice to do this periodically, or when the vehicle comes back into the frustum
    this.HideWheelComponents();

    // kinda glitchy/slow
    let forward = Quaternion.GetForward(this.component.stats.d_orientation);
    forward.Z = 0.0;
    let y = Quaternion.BuildFromDirectionVector(forward, FlightUtils.Up());
    let cq = Quaternion.Conjugate(this.component.stats.d_orientation);
    // Quaternion.SetZRot(cq, 0.0);
    this.ui_info.SetLocalOrientation(cq * y);

    let thrusterAmount = Vector4.Dot(new Vector4(0.0, 0.0, 1.0, 0.0), force);
    // let thrusterAmount = ClampF(this.surge.GetValue(), 0.0, 1.0) * 1.0;
    if this.HasFWheel() {
      this.f_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount + torque.X + torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.component.fl_tire.SetLocalOrientation(Quaternion.Slerp(this.component.fl_tire.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0),
          0.0,
          torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -45.0, 45.0)
        )), 0.1));
      }
    }
    if this.HasBWheel() {
      this.b_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount + torque.X - torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.component.bl_tire.SetLocalOrientation(Quaternion.Slerp(this.component.bl_tire.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          0.0,
          torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -45.0, 45.0)
        )), 0.1));
      }
    }
    if this.HasBLWheel() {
      this.bl_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount + torque.X + torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.bl_thruster.SetLocalOrientation(Quaternion.Slerp(this.bl_thruster.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          -ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0),
          180.0,
          -torque.Z * 0.5 - ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -15.0, 15.0)
        )), 0.1));
      }
      this.bl_retroFx.SetBlackboardValue(n"thruster_amount", (Vector4.Dot(new Vector4(1.0, 0.0, 0.0, 0.0), force) + torque.Z) * 0.1);
    }
    if this.HasBRWheel() {
      this.br_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount + torque.X - torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.br_thruster.SetLocalOrientation(Quaternion.Slerp(this.br_thruster.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          0.0,
          torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -15.0, 15.0)
        )), 0.1));
      }
      this.br_retroFx.SetBlackboardValue(n"thruster_amount", (Vector4.Dot(new Vector4(-1.0, 0.0, 0.0, 0.0), force) - torque.Z) * 0.1);
    }
    if this.HasFLWheel() {
      this.fl_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount - torque.X + torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.fl_thruster.SetLocalOrientation(Quaternion.Slerp(this.fl_thruster.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          -ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          180.0,
          // torque.Z * 0.5 - ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -15.0, 15.0)
          0.0
        )), 0.1));
      }
      this.fl_retroFx.SetBlackboardValue(n"thruster_amount", (Vector4.Dot(new Vector4(1.0, 0.0, 0.0, 0.0), force) - torque.Z) * 0.1);
    }
    if this.HasFRWheel() {
      this.fr_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount - torque.X - torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.fr_thruster.SetLocalOrientation(Quaternion.Slerp(this.fr_thruster.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          0.0,
          -torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -15.0, 15.0)
        )), 0.1));
      }
      this.fr_retroFx.SetBlackboardValue(n"thruster_amount", (Vector4.Dot(new Vector4(-1.0, 0.0, 0.0, 0.0), force) + torque.Z) * 0.1);
    }
    if this.HasFLBWheel() {
      this.flb_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount - torque.X + torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.component.hood.SetLocalOrientation(Quaternion.Slerp(this.component.hood.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          0.0,
          -torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -45.0, 45.0)
        )), 0.1));
      }
    }
    if this.HasFRBWheel() {
      this.frb_fx.SetBlackboardValue(n"thruster_amount", (thrusterAmount - torque.X - torque.Y + AbsF(force.Y)) * FlightSettings.GetFloat(n"thrusterFactor"));
      if thrusterAmount > 0.0 {
        this.component.trunk.SetLocalOrientation(Quaternion.Slerp(this.component.trunk.GetLocalOrientation(), EulerAngles.ToQuat(new EulerAngles(
          ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()), -45.0, 45.0), 
          0.0,
          -torque.Z * 0.5 + ClampF(Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()), -45.0, 45.0)
        )), 0.1));
      }
    }

    // +x = torwards front
    // +y = rotate left z
    // +z = towards right 
    // let forceQuat = Quaternion.BuildFromDirectionVector(-force, this.component.stats.d_localUp);
    // let quat = EulerAngles.ToQuat(new EulerAngles(
    //   Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Right()),
    //   Vector4.GetAngleDegAroundAxis(FlightUtils.Up(), force, FlightUtils.Forward()),
    //   0
    // ));
    // this.component.bl_tire.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(
    //   -force.Y,
    //   0.0, 
    //   torque.Z - force.X
    // )));
    // this.component.br_tire.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(
    //   -force.Y, 
    //   0.0, 
    //   torque.Z - force.X
    // )));
    // this.component.fl_tire.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(
    //   -force.Y, 
    //   0.0, 
    //   -torque.Z - force.X
    // )));
    // this.component.fr_tire.SetLocalOrientation(EulerAngles.ToQuat(new EulerAngles(
    //   -force.Y, 
    //   0.0, 
    //   -torque.Z - force.X
    // )));
    // +x = torwards front
    // +y = rotate left z
    // +z = towards right 
    // WorldTransform.SetPosition(this.bl_fx_wt, this.audio.GetPosition(n"wheel_back_left"));
    // WorldTransform.SetPosition(this.br_fx_wt, this.audio.GetPosition(n"wheel_back_right"));
    // WorldTransform.SetPosition(this.fl_fx_wt, this.audio.GetPosition(n"wheel_front_left"));
    // WorldTransform.SetPosition(this.fr_fx_wt, this.audio.GetPosition(n"wheel_front_right"));

    // WorldTransform.SetOrientationEuler(this.bl_fx_wt, new EulerAngles(
    //   Vector4.Dot(force, -this.stats.d_forward), 
    //   0.0, 
    //   torque.Z + Vector4.Dot(force, -this.stats.d_right)
    // ));
    // WorldTransform.SetOrientationEuler(this.br_fx_wt, new EulerAngles(
    //   Vector4.Dot(force, -this.stats.d_forward), 
    //   0.0, 
    //   torque.Z + Vector4.Dot(force, -this.stats.d_right)
    // ));
    // WorldTransform.SetOrientationEuler(this.fl_fx_wt, new EulerAngles(
    //   Vector4.Dot(force, -this.stats.d_forward), 
    //   0.0, 
    //   -torque.Z + Vector4.Dot(force, -this.stats.d_right)
    // ));
    // WorldTransform.SetOrientationEuler(this.fr_fx_wt, new EulerAngles(
    //   Vector4.Dot(force, -this.stats.d_forward), 
    //   0.0, 
    //   -torque.Z + Vector4.Dot(force, -this.stats.d_right)
    // ));
    
    // this.bl_fx.UpdateTransform(this.bl_fx_wt);
    // this.br_fx.UpdateTransform(this.br_fx_wt);
    // this.fl_fx.UpdateTransform(this.fl_fx_wt);
    // this.fr_fx.UpdateTransform(this.fr_fx_wt);
  }

  public func HideWheelComponents() {
    // hide wheels, tires & brakes (chassis)

    // if this.chassis.IsEnabled() {
    //   this.chassis.Toggle(false);
    // }

    for c in this.fc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.blc, c);
    }
    for c in this.bc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.blc, c);
    }
    for c in this.blc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.blc, c);
    }
    for c in this.brc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.brc, c);
    }
    for c in this.flc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.flc, c);
    }
    for c in this.frc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.frc, c);
    }
    for c in this.flbc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.frc, c);
    }
    for c in this.frbc {
      if c.IsEnabled() {
        c.Toggle(false);
      }
      // ArrayRemove(this.frc, c);
    }
  }

  public func ShowWheelComponents() {
    // this.chassis.Toggle(true);

    for c in this.fc {
        c.Toggle(true);
    }
    for c in this.bc {
        c.Toggle(true);
    }
    for c in this.blc {
        c.Toggle(true);
    }
    for c in this.brc {
        c.Toggle(true);
    }
    for c in this.flc {
        c.Toggle(true);
    }
    for c in this.frc {
        c.Toggle(true);
    }
    for c in this.flbc {
        c.Toggle(true);
    }
    for c in this.frbc {
        c.Toggle(true);
    }
  }
}