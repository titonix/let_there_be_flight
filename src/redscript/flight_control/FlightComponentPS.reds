// VehicleObject

@addMethod(VehicleObject)
public const func IsQuickHackAble() -> Bool {
    FlightLog.Info("[VehicleObject] IsQuickHackAble");
  return true;
}

@addMethod(VehicleObject)
public const func IsPotentiallyQuickHackable() -> Bool {
    FlightLog.Info("[VehicleObject] IsPotentiallyQuickHackable");
  return true;
}

@addMethod(VehicleObject)
public const func IsQuickHacksExposed() -> Bool {
    FlightLog.Info("[VehicleObject] IsQuickHacksExposed");
  return true;
}

@addMethod(VehicleObject)
protected cb func OnHUDInstruction(evt: ref<HUDInstruction>) -> Bool {
  super.OnHUDInstruction(evt);
  if evt.quickhackInstruction.ShouldProcess() {
    this.TryOpenQuickhackMenu(evt.quickhackInstruction.ShouldOpen());
  };
}

@addMethod(VehicleObject)
public const func CanRevealRemoteActionsWheel() -> Bool {
    FlightLog.Info("[VehicleObject] CanRevealRemoteActionsWheel");
  return true;
}

// VehicleComponentPS

@wrapMethod(VehicleComponentPS)
protected const func CanCreateAnyQuickHackActions() -> Bool {
  //FlightLog.Info("[VehicleComponentPS] CanCreateAnyQuickHackActions");
  // working
  return wrappedMethod() || true;
}

@addMethod(VehicleComponentPS)
public final const func IsPotentiallyQuickHackable() -> Bool {
  //FlightLog.Info("[VehicleComponentPS] IsPotentiallyQuickHackable");
  //working
  return true;
}

@replaceMethod(VehicleComponentPS)
protected func GetQuickHackActions(out actions: array<ref<DeviceAction>>, context: GetActionsContext) -> Void {
  FlightLog.Info("[VehicleComponentPS] GetQuickHackActions");
  // let currentAction: ref<ScriptableDeviceAction>;
  // let controllerPS: ref<vehicleControllerPS> = this.GetVehicleControllerPS();
  // let vehicleState: vehicleEState = controllerPS.GetState();
  // if Equals(vehicleState, vehicleEState.Default) {
    // if !controllerPS.IsAlarmOn() {
      // currentAction = this.ActionForceCarAlarm();
      // currentAction.SetObjectActionID(t"DeviceAction.MalfunctionClassHack");
      // ArrayPush(actions, currentAction);
    // };
  // };
  let action = new QuickHackFlightMalfunction();
  action.SetUp(this);
  action.SetProperties();
  action.AddDeviceName(this.GetDeviceName());
  action.CreateInteraction();
  action.SetObjectActionID(t"DeviceAction.MalfunctionClassHack");
  action.SetDurationValue(0.1);
  // action.SetInactiveWithReason(!this.IsDistracting(), "LocKey#7004");
  ArrayPush(actions, action);
  this.FinalizeGetQuickHackActions(actions, context);
}

@wrapMethod(VehicleComponentPS)
protected func Initialize() -> Void {
  wrappedMethod();
  this.m_disableQuickHacks = false;
  this.m_debugExposeQuickHacks = true;
  this.UpdateQuickHackableState(true);
  this.EnableDevice();
}

@addMethod(VehicleComponentPS)
public func OnQuickHackFlightMalfunction(evt: ref<QuickHackFlightMalfunction>) -> EntityNotificationType {
  // let type: EntityNotificationType = this.OnQuickHackFlightMalfunction(evt);
  // if Equals(type, EntityNotificationType.DoNotNotifyEntity) {
  //   return type;
  // };
  if evt.IsStarted() {
    FlightLog.Info("[VehicleComponentPS] OnQuickHackFlightMalfunction");
    // this.ExecutePSAction(this.FireVerticalImpulse());
    let impulseEvent: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
    impulseEvent.radius = 1.0;
    impulseEvent.worldPosition = Vector4.Vector4To3(this.GetOwnerEntity().GetWorldPosition());
    impulseEvent.worldImpulse = new Vector3(0.0, 0.0, 10000.0);
    this.GetOwnerEntity().QueueEvent(impulseEvent);
  };
  this.UseNotifier(evt);
  return EntityNotificationType.DoNotNotifyEntity;
}

// custom class

// public class FlightComponentPS extends ScriptableDeviceComponentPS {
//   protected func Initialize() -> Void {
//     super.Initialize();
//     this.m_disableQuickHacks = false;
//     this.m_debugExposeQuickHacks = true;
//     this.UpdateQuickHackableState(true);
//   }

//   public const func IsQuickHackAble() -> Bool {
//     FlightLog.Info("[FlightComponentPS] IsQuickHackAble");
//     return true;
//   }

//   public func IsQuickHacksExposed() -> Bool {
//     FlightLog.Info("[FlightComponentPS] IsQuickHacksExposed");
//     return true;
//   }

//   public func OnSetExposeQuickHacks(evt: ref<SetExposeQuickHacks>) -> EntityNotificationType {
//     super.OnSetExposeQuickHacks(evt);
//     return EntityNotificationType.SendThisEventToEntity;
//   }

//   protected const func CanCreateAnyQuickHackActions() -> Bool {
//     return true;
//   }

//   protected func GetQuickHackActions(out actions: array<ref<DeviceAction>>, context: GetActionsContext) -> Void {
//     FlightLog.Info("[FlightComponentPS] GetQuickHackActions");
//     let action: ref<ScriptableDeviceAction> = this.ActionQuickHackFlightMalfunction();
//     action.SetObjectActionID(t"DeviceAction.MalfunctionClassHack");
//     action.SetDurationValue(0.1);
//     // action.SetInactiveWithReason(!this.IsDistracting(), "LocKey#7004");
//     ArrayPush(actions, action);
//     this.FinalizeGetQuickHackActions(actions, context);
//   }

//   protected func ActionQuickHackFlightMalfunction() -> ref<QuickHackFlightMalfunction> {
//     let action: ref<QuickHackFlightMalfunction> = new QuickHackFlightMalfunction();
//     action.SetUp(this);
//     action.SetProperties();
//     action.AddDeviceName(this.GetDeviceName());
//     action.CreateInteraction();
//     action.SetDurationValue(0.1);
//     return action;
//   }

//   public func OnQuickHackFlightMalfunction(evt: ref<QuickHackFlightMalfunction>) -> EntityNotificationType {
//     FlightLog.Info("[FlightComponentPS] OnQuickHackFlightMalfunction");
//     let type: EntityNotificationType = this.OnQuickHackFlightMalfunction(evt);
//     // if Equals(type, EntityNotificationType.DoNotNotifyEntity) {
//     //   return type;
//     // };
//     if evt.IsStarted() {
//       // this.ExecutePSAction(this.FireVerticalImpulse());
//       this.FireVerticalImpulse();
//     };
//     return EntityNotificationType.SendThisEventToEntity;
//   }

//   public func GetVehicle() -> wref<VehicleObject> {
//     return GameInstance.FindEntityByID(this.GetGameInstance(), PersistentID.ExtractEntityID(this.GetID())) as VehicleObject;
//   }

//   public func FireVerticalImpulse() {
//     let impulseEvent: ref<PhysicalImpulseEvent> = new PhysicalImpulseEvent();
//     impulseEvent.radius = 1.0;
//     impulseEvent.worldPosition = Vector4.Vector4To3(this.GetVehicle().GetWorldPosition());
//     impulseEvent.worldImpulse = new Vector3(0.0, 0.0, 10000.0);
//     this.GetVehicle().QueueEvent(impulseEvent);
//   }
// }
