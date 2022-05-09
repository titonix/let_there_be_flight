#include <RED4ext/InstanceType.hpp>
#include <RED4ext/RED4ext.hpp>
#include <RED4ext/RTTITypes.hpp>
#include <RED4ext/Scripting/IScriptable.hpp>
#include <RED4ext/Scripting/Natives/Generated/Vector4.hpp>
#include <RED4ext/Scripting/Natives/Generated/ent/EffectDesc.hpp>
#include <RED4ext/Scripting/Natives/Generated/ent/EffectSpawnerComponent.hpp>
#include <RED4ext/Scripting/Natives/Generated/game/data/VehicleTPPCameraParams_Record.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/BoxBlurEffect.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/EBlurDimension.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/IEffect.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/ImageWidget.hpp>
#include <RED4ext/Scripting/Natives/Generated/ink/TextureAtlas.hpp>
#include <RED4ext/Scripting/Natives/Generated/physics/SystemBody.hpp>
#include <RED4ext/Scripting/Natives/Generated/physics/SystemResource.hpp>
#include <RED4ext/Scripting/Natives/Generated/red/ResourceReferenceScriptToken.hpp>
#include <RED4ext/Scripting/Natives/Generated/vehicle/BaseObject.hpp>
#include <RED4ext/Scripting/Natives/Generated/vehicle/ChassisComponent.hpp>
#include <RED4ext/Scripting/Natives/ScriptGameInstance.hpp>
#include <iostream>

#include "FlightAudio.hpp"
#include "Utils.hpp"
#include "stdafx.hpp"
//#include "FlightHUDGameController.hpp"
#include "FlightLog.hpp"
#include "FlightStats_Record.hpp"
#include "FlightSystem.hpp"
#include "FmodHelper.hpp"

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterTypes() {
  spdlog::info("Registering classes & types");
  FlightAudio::RegisterTypes();
  FlightLog::RegisterTypes();
  FlightSystem::RegisterTypes();
  // FlightHUDGameController::RegisterTypes();
  // FlightStats_Record::RegisterTypes();
}

void SetAtlasResource(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, bool *aOut, int64_t a4) {
  RED4ext::red::ResourceReferenceScriptToken value;
  RED4ext::GetParameter(aFrame, &value);
  aFrame->code++; // skip ParamEnd
  auto rtti = RED4ext::CRTTISystem::Get();

  // auto inkImageWidget = rtti->GetClass("inkImageWidget");
  // auto setAtlasResource = inkImageWidget->GetFunction("SetAtlasResource");
  // RED4ext::StackArgs_t args;
  // args.emplace_back(nullptr, &value); // or value, I don't remember how it
  // should be passed. RED4ext::ExecuteFunction(aContext, setAtlasResource,
  // aOut, args);

  auto redResourceReferenceScriptToken = rtti->GetClass("redResourceReferenceScriptToken");
  auto IsValid = redResourceReferenceScriptToken->GetFunction("IsValid");
  bool valid;
  RED4ext::ExecuteFunction(redResourceReferenceScriptToken, IsValid, &valid, &value);
  if (valid) {
    auto inkMaskWidget = rtti->GetClass("inkMaskWidget");
    // uint64_t resource =
    // RED4ext::FNV1a64("base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
    inkMaskWidget->GetProperty("textureAtlas")->SetValue(aContext, value.resource);
    if (aOut != nullptr) {
      *aOut = true;
    }
  } else {
    if (aOut != nullptr) {
      *aOut = false;
    }
  }
}

void CreateEffect(RED4ext::IScriptable *apContext, RED4ext::CStackFrame *apFrame, void *apOut, int64_t a4) {
  RED4ext::CName typeName;
  RED4ext::CName effectName;

  RED4ext::GetParameter(apFrame, &typeName);
  RED4ext::GetParameter(apFrame, &effectName);
  apFrame->code++; // skip ParamEnd

  auto pRtti = RED4ext::CRTTISystem::Get();

  auto pEffectClass = pRtti->GetClass(typeName);
  auto pEffectInstance = reinterpret_cast<RED4ext::ISerializable *>(pEffectClass->AllocInstance());
  auto pEffectHandle = RED4ext::Handle<RED4ext::ISerializable>(pEffectInstance);

  pEffectClass->GetProperty("effectName")->SetValue(pEffectInstance, effectName);

  auto pWidgetClass = pRtti->GetClass("inkWidget");
  auto pEffectsProp = pWidgetClass->GetProperty("effects");
  auto pEffectsType = reinterpret_cast<RED4ext::CRTTIArrayType *>(pEffectsProp->type);
  auto pEffectsArray = pEffectsProp->GetValue<RED4ext::DynArray<void *> *>(apContext);

  auto lastIndex = pEffectsType->GetLength(pEffectsArray);

  pEffectsType->InsertAt(pEffectsArray, lastIndex);

  auto pLastElement = pEffectsType->GetElement(pEffectsArray, lastIndex);

  pEffectsType->GetInnerType()->Assign(pLastElement, &pEffectHandle);
}

void SetBlurDimension(RED4ext::IScriptable *apContext, RED4ext::CStackFrame *apFrame, bool *apOut, int64_t a4) {
  RED4ext::CName effectName;
  RED4ext::ink::EBlurDimension blurDimension;
  RED4ext::GetParameter(apFrame, &effectName);
  RED4ext::GetParameter(apFrame, &blurDimension);
  apFrame->code++; // skip ParamEnd

  auto pRtti = RED4ext::CRTTISystem::Get();

  auto pEffectClass = pRtti->GetClass("inkBoxBlurEffect");
  auto pGenericEffectClass = pRtti->GetClass("inkIEffect");

  auto pWidgetClass = pRtti->GetClass("inkWidget");
  auto pEffectsProp = pWidgetClass->GetProperty("effects");
  auto pEffectsType = reinterpret_cast<RED4ext::CRTTIArrayType *>(pEffectsProp->type);
  auto pEffectsArray = pEffectsProp->GetValue<RED4ext::DynArray<void *> *>(apContext);

  auto pEffectsArraySize = pEffectsType->GetLength(pEffectsArray);

  bool found = false;

  for (int i = 0; i < pEffectsArraySize; i++) {
    auto pEffect = (RED4ext::Handle<RED4ext::ISerializable> *)pEffectsType->GetElement(pEffectsArray, i);
    RED4ext::CName pEffectName =
        pGenericEffectClass->GetProperty("effectName")->GetValue<RED4ext::CName>(pEffect->instance);
    if (pEffectName == effectName) {
      pEffectClass->GetProperty("blurDimension")->SetValue(pEffect->instance, blurDimension);
      found = true;
      break;
    }
  }

  if (apOut) {
    *apOut = found;
  }
}

void SetShapeResource(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, void *aOut, int64_t a4) {
  RED4ext::red::ResourceReferenceScriptToken value;
  RED4ext::GetParameter(aFrame, &value);
  aFrame->code++; // skip ParamEnd
  auto rtti = RED4ext::CRTTISystem::Get();

  // auto inkImageWidget = rtti->GetClass("inkImageWidget");
  // auto setAtlasResource = inkImageWidget->GetFunction("SetAtlasResource");
  // RED4ext::StackArgs_t args;
  // args.emplace_back(nullptr, &value); // or value, I don't remember how it
  // should be passed. RED4ext::ExecuteFunction(aContext, setAtlasResource,
  // aOut, args);

  auto inkShapeWidget = rtti->GetClass("inkShapeWidget");
  // uint64_t resource =
  // RED4ext::FNV1a64("base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
  inkShapeWidget->GetProperty("shapeResource")->SetValue(aContext, value.resource);
}

void ChassisGetComOffset(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, RED4ext::Transform *aOut,
                         int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto rtti = RED4ext::CRTTISystem::Get();
  auto vccClass = rtti->GetClass("vehicleChassisComponent");
  auto crProp = vccClass->GetProperty("collisionResource");
  auto cr = crProp->GetValue<RED4ext::Ref<RED4ext::physics::SystemResource>>(aContext);
  auto hpsr = (RED4ext::Handle<RED4ext::physics::SystemResource> *)(cr.unk08 + 0x28);
  auto psr = hpsr->GetPtr();
  RED4ext::Handle<RED4ext::physics::SystemBody> hpsb = psr->bodies[0];
  auto params = hpsb->params;

  if (aOut) {
    *aOut = params.comOffset;
  }
}

void VehicleUsesInertiaTensor(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, bool *aOut, int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ps = v->physicsStruct;

  if (aOut) {
    *aOut = ps->usesInertiaTensor;
  }
}

short PhysicsStructUpdate(RED4ext::physics::VehiclePhysicsStruct *ps);
decltype(&PhysicsStructUpdate) PhysicsStructUpdate_Original;

short PhysicsStructUpdate(RED4ext::physics::VehiclePhysicsStruct* ps) { 

  // apply force to linear velocity
  RED4ext::Vector3 unlimitedVelocity;
  unlimitedVelocity.X = ps->velocity.X + ps->force.X * ps->inverseMass;
  unlimitedVelocity.Y = ps->velocity.Y + ps->force.Y * ps->inverseMass;
  unlimitedVelocity.Z = ps->velocity.Z + ps->force.Z * ps->inverseMass;

  auto result = PhysicsStructUpdate_Original(ps);

  if (result != 1) {
    ps->velocity = unlimitedVelocity;
  }

  return result;

  //ps->force.X = 0.0;
  //ps->force.Y = 0.0;
  //ps->force.Z = 0.0;

  //auto speedSquared = pow(ps->velocity.X, 2) + pow(ps->velocity.Y, 2) + pow(ps->velocity.Z, 2);
  //auto result = _fdclass(speedSquared);

  //// knock-down velocity if too fast
  //if (result == 1 || speedSquared > 10000.0) {
  //  ps->velocity.X = 0.0;
  //  ps->velocity.Y = 0.0;
  //  ps->velocity.Z = 0.0;
  //}

  // apply torque to angular velocity
  //auto deltaAV = _mm_add_ps(_mm_add_ps(
  //  _mm_mul_ps(_mm_set1_ps(ps->torque.Y), _mm_load_ps((float*)&ps->invertedWorldInertiaTensor.Y)),
  //  _mm_mul_ps(_mm_set1_ps(ps->torque.X), _mm_load_ps((float*)&ps->invertedWorldInertiaTensor.X))),
  //  _mm_mul_ps(_mm_set1_ps(ps->torque.Z), _mm_load_ps((float*)&ps->invertedWorldInertiaTensor.Z)));

  //ps->angularVelocity.X = deltaAV.m128_f32[0] + ps->angularVelocity.X;
  //ps->angularVelocity.Y = deltaAV.m128_f32[1] + ps->angularVelocity.Y;
  //ps->angularVelocity.Z = deltaAV.m128_f32[2] + ps->angularVelocity.Z;

  // auto deltaAV = _mm_add_ps(_mm_add_ps(
  //  _mm_mul_ps(_mm_shuffle_ps(_mm_set_ss(ps->torque.Y), _mm_set_ss(ps->torque.Y), 0), ps->invertedWorldInertiaTensor.Y.raw),
  //  _mm_mul_ps(_mm_shuffle_ps(_mm_set_ss(ps->torque.X), _mm_set_ss(ps->torque.X), 0), ps->invertedWorldInertiaTensor.X.raw)),
  //  _mm_mul_ps(_mm_shuffle_ps(_mm_set_ss(ps->torque.Z), _mm_set_ss(ps->torque.Z), 0), ps->invertedWorldInertiaTensor.Z.raw));
  //
  // ps->angularVelocity.X = deltaAV.m128_f32[0] + ps->angularVelocity.X;
  // ps->angularVelocity.Y = deltaAV.m128_f32[1] + ps->angularVelocity.Y;
  // ps->angularVelocity.Z = deltaAV.m128_f32[2] + ps->angularVelocity.Z;

  //ps->torque.X = 0.0;
  //ps->torque.Y = 0.0;
  //ps->torque.Z = 0.0;

  // apply angular velocity to quaternion
  // https://www.ashwinnarayan.com/post/how-to-integrate-quaternions/
  //auto w = ps->currentTransform.Orientation.k;
  //auto x = ps->currentTransform.Orientation.r;
  //auto y = ps->currentTransform.Orientation.i;
  //auto z = ps->currentTransform.Orientation.j;
  //auto aV = ps->angularVelocity;

  //auto wp = 0.5 * (x * -aV.X + y * -aV.Y + z * -aV.Z);
  //auto xp = 0.5 * (w * aV.X + y * aV.Z + z * -aV.Y);
  //auto yp = 0.5 * (w * aV.Y + x * -aV.Z + z * aV.X);
  //auto zp = 0.5 * (w * aV.Z + x * aV.Y + y * -aV.X);

  //ps->orientation.i = y;
  //ps->orientation.j = z;
  //ps->orientation.k = w;
  //ps->orientation.r = x;

  //auto o = ps->currentTransform.Orientation;
  //ps->orientation.i = (o.k * ps->angularVelocity.Y + o.r * ps->angularVelocity.X - o.j * ps->angularVelocity.Z) * 0.5;
  //ps->orientation.j = (o.i * ps->angularVelocity.Z + o.r * ps->angularVelocity.Y - o.k * ps->angularVelocity.X) * 0.5;
  //ps->orientation.k = (-o.i * ps->angularVelocity.X - o.j * ps->angularVelocity.Y - o.k * ps->angularVelocity.Z) * 0.5;
  //ps->orientation.r = (o.r * ps->angularVelocity.Z + o.j * ps->angularVelocity.X - o.i * ps->angularVelocity.Y) * 0.5;

  return result;
}

void VehicleTurnOffAirControl(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, bool *aOut, int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ac = v->airControl;

  ac->anglePID.X = 0.0;
  ac->velocityPID.X = 0.0;
  ac->yaw.multiplier = 0.0;
  ac->roll.multiplier = 0.0;
  ac->pitch.multiplier = 0.0;

  if (aOut) {
    *aOut = true;
  }
}

void VehicleGetMomentOfInertiaScale(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame,
                                    RED4ext::Vector3 *aOut,
                                    int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ps = v->physicsStruct;

  if (aOut) {
    *aOut = ps->momentOfInertiaScale;
  }
}

void VehicleGetInertiaTensor(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, RED4ext::Matrix *aOut,
                             int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ps = v->physicsStruct;

  if (aOut) {
    *aOut = ps->localInertiaTensor;
  }
}

void VehicleGetCenterOfMass(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, RED4ext::Vector3 *aOut,
                            int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ps = v->physicsStruct;

  if (aOut) {
    *aOut = ps->centerOfMass;
  }
}

void VehicleGetAngularVelocity(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, RED4ext::Vector3 *aOut,
                            int64_t a4) {
  aFrame->code++; // skip ParamEnd

  auto v = reinterpret_cast<RED4ext::vehicle::BaseObject *>(aContext);
  auto ps = v->physicsStruct;

  if (aOut) {
    *aOut = ps->angularVelocity;
  }
}

void EffectSpawnerAddEffect(RED4ext::IScriptable *aContext, RED4ext::CStackFrame *aFrame, void *aOut, int64_t a4) {
  // RED4ext::red::ResourceReferenceScriptToken value;
  // RED4ext::CName name;
  // bool valid;
  // RED4ext::GetParameter(aFrame, &value);
  // RED4ext::GetParameter(aFrame, &name);
  aFrame->code++; // skip ParamEnd

  spdlog::info("[EffectSpawnerComponent] Adding New Effect");

  auto rtti = RED4ext::CRTTISystem::Get();

  // auto rrst = rtti->GetClass("redResourceReferenceScriptToken");
  // auto IsValid = rrst->GetFunction("IsValid");
  // RED4ext::ExecuteFunction(rrst, IsValid, &valid, &value);

  // if (valid) {
  auto esc = reinterpret_cast<RED4ext::ent::EffectSpawnerComponent *>(aContext);

  auto effectDescCls = rtti->GetClass("entEffectDesc");
  auto ceei = rtti->GetClass("worldCompiledEffectEventInfo");
  auto cepi = rtti->GetClass("worldCompiledEffectPlacementInfo");
  auto v3 = rtti->GetClass("Vector3");
  auto q = rtti->GetClass("Quaternion");
  auto ed = reinterpret_cast<RED4ext::ent::EffectDesc *>(effectDescCls->AllocInstance());

  ed->effectName = "test_effect";
  ed->id.unk00 = 2738936757675335681; // 2738936757675335680 + 1
  auto existingEffect = (RED4ext::ent::EffectDesc *)esc->effectDescs[0].instance;
  ed->effect.ref = existingEffect->effect.ref;
  // ed->effect.ref = 3990659875028156682;

  auto eventInfo = reinterpret_cast<RED4ext::world::CompiledEffectEventInfo *>(ceei->AllocInstance());
  eventInfo->eventRUID.unk00 = 2740474573584572416;
  eventInfo->placementIndexMask = 1;
  eventInfo->flags = 1;
  ed->compiledEffectInfo.eventsSortedByRUID.EmplaceBack(*eventInfo);

  auto placementInfo = reinterpret_cast<RED4ext::world::CompiledEffectPlacementInfo *>(cepi->AllocInstance());
  placementInfo->flags = 5;
  placementInfo->placementTagIndex = 0;
  placementInfo->relativePositionIndex = 0;
  placementInfo->relativeRotationIndex = 0;
  ed->compiledEffectInfo.placementInfos.EmplaceBack(*placementInfo);

  ed->compiledEffectInfo.placementTags.EmplaceBack("fx_holo_corner_br");

  auto vector = reinterpret_cast<RED4ext::Vector3 *>(v3->AllocInstance());
  ed->compiledEffectInfo.relativePositions.EmplaceBack(*vector);

  auto quaternion = reinterpret_cast<RED4ext::Quaternion *>(q->AllocInstance());
  quaternion->r = 1.0;
  ed->compiledEffectInfo.relativeRotations.EmplaceBack(*quaternion);

  auto edHandle = RED4ext::Handle<RED4ext::ent::EffectDesc>(ed);

  esc->effectDescs.EmplaceBack(edHandle);

  spdlog::info("[EffectSpawnerComponent] New Effect Added");
  //}

  // if (aOut) {
  //  *aOut = valid;
  //}
}

// struct gamePSMVehicle : RED4ext::CBaseRTTIType {
//};

// void TppFlightCameraParams(RED4ext::IScriptable* apContext,
// RED4ext::CStackFrame* apFrame, RED4ext::VehicleTPPCameraParams_Record* apOut,
// int64_t a4) {
//    auto rtti = RED4ext::CRTTISystem::Get();
//    auto TweakDBInterface = rtti->GetClass("TweakDBInterface");
//    auto GetVehicleTPPCameraParamsRecord =
//    TweakDBInterface->GetFunction("GetVehicleTPPCameraParamsRecord"); auto
//    value = RED4ext::TweakDBID::TweakDBID("Camera.VehicleTPP_FlightParams");
//    RED4ext::StackArgs_t args;
//    args.emplace_back(nullptr, &value);
//    RED4ext::ExecuteFunction(TweakDBInterface,
//    GetVehicleTPPCameraParamsRecord, apOut, args);
//}
//
// void TppCameraParamsHandle(RED4ext::IScriptable* apContext,
// RED4ext::CStackFrame* apFrame,
// RED4ext::Handle<RED4ext::VehicleTPPCameraParams_Record*>* apOut, int64_t a4)
// {
//    auto rtti = RED4ext::CRTTISystem::Get();
//    auto TweakDBInterface = rtti->GetClass("TweakDBInterface");
//    auto GetVehicleTPPCameraParamsRecord =
//    TweakDBInterface->GetFunction("GetVehicleTPPCameraParamsRecord"); auto
//    value = RED4ext::TweakDBID::TweakDBID("Camera.VehicleTPP_FlightParams");
//    RED4ext::StackArgs_t args;
//    args.emplace_back(nullptr, &value);
//    RED4ext::ExecuteFunction(TweakDBInterface,
//    GetVehicleTPPCameraParamsRecord, apOut, args);
//}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterTypes() {
  spdlog::info("Registering functions");
  FlightAudio::RegisterFunctions();
  FlightLog::RegisterFunctions();
  FlightSystem::RegisterFunctions();
  // FlightHUDGameController::RegisterFunctions();
  RED4ext::CRTTISystem::Get()->RegisterScriptName("entBaseCameraComponent", "BaseCameraComponent");
  // RED4ext::CRTTISystem::Get()->RegisterScriptName("entColliderComponent",
  // "ColliderComponent"); FlightStats_Record::RegisterFunctions();

  auto rtti = RED4ext::CRTTISystem::Get();

  auto inkMaskWidget = rtti->GetClass("inkMaskWidget");
  auto setAtlasTextureFunc = RED4ext::CClassFunction::Create(inkMaskWidget, "SetAtlasResource", "SetAtlasResource",
                                                             &SetAtlasResource, {.isNative = true});
  inkMaskWidget->RegisterFunction(setAtlasTextureFunc);

  auto inkShapeWidget = rtti->GetClass("inkShapeWidget");
  auto setShapeResourceFunc = RED4ext::CClassFunction::Create(inkShapeWidget, "SetShapeResource", "SetShapeResource",
                                                              &SetShapeResource, {.isNative = true});
  inkShapeWidget->RegisterFunction(setShapeResourceFunc);

  auto inkWidget = rtti->GetClass("inkWidget");

  auto createEffectFunc =
      RED4ext::CClassFunction::Create(inkWidget, "CreateEffect", "CreateEffect", &CreateEffect, {.isNative = true});
  inkWidget->RegisterFunction(createEffectFunc);

  auto setBlurDimensionFunc = RED4ext::CClassFunction::Create(inkWidget, "SetBlurDimension", "SetBlurDimension",
                                                              &SetBlurDimension, {.isNative = true});
  inkWidget->RegisterFunction(setBlurDimensionFunc);

  // auto getEffectFunc = RED4ext::CClassFunction::Create(inkWidget,
  // "GetEffect", "GetEffect", &GetEffect, { .isNative = true });
  // getEffectFunc->AddParam("CName", "effectName");
  // getEffectFunc->SetReturnType("inkIEffect");
  // inkWidget->RegisterFunction(getEffectFunc);

  auto gamePSMVehicleEnum = rtti->GetEnum("gamePSMVehicle");
  gamePSMVehicleEnum->hashList.PushBack("Flight");
  gamePSMVehicleEnum->valueList.PushBack(8);

  auto UIGameContextEnum = rtti->GetEnum("UIGameContext");
  UIGameContextEnum->hashList.PushBack("VehicleFlight");
  UIGameContextEnum->valueList.PushBack(10);

  auto NavGenAgentSizeEnum = rtti->GetEnum("NavGenAgentSize");
  NavGenAgentSizeEnum->hashList.PushBack("Vehicle");
  NavGenAgentSizeEnum->valueList.PushBack(1);

  // auto gamedataVehicle_Record = rtti->GetClass("gamedataVehicle_Record");
  // auto TppCameraParamsOld =
  // gamedataVehicle_Record->GetFunction("TppCameraParams");

  // auto TppCameraParamsNew =
  // RED4ext::CClassFunction::Create(gamedataVehicle_Record,
  // "TppFlightCameraParams", "TppFlightCameraParams", &TppFlightCameraParams, {
  // .isNative = true });
  //
  // TppCameraParamsNew->fullName = TppCameraParamsOld->fullName;
  // TppCameraParamsNew->shortName = TppCameraParamsOld->shortName;

  // TppCameraParamsNew->returnType = TppCameraParamsOld->returnType;
  // for (auto* p : TppCameraParamsOld->params)
  //{
  //    TppCameraParamsNew->params.PushBack(p);
  //}

  // for (auto* p : TppCameraParamsOld->localVars)
  //{
  //    TppCameraParamsNew->localVars.PushBack(p);
  //}

  // TppCameraParamsNew->unk20 = TppCameraParamsOld->unk20;
  ////std::copy_n(TppCameraParamsOld->unk78,
  /// std::size(TppCameraParamsOld->unk78), TppCameraParamsNew->unk78);
  // TppCameraParamsNew->unk48 = TppCameraParamsOld->unk48;
  // TppCameraParamsNew->unkAC = TppCameraParamsOld->unkAC;
  // TppCameraParamsNew->flags = TppCameraParamsOld->flags;
  // TppCameraParamsNew->parent = TppCameraParamsOld->parent;
  // TppCameraParamsNew->flags.isNative = true;

  //// Swap the content of the real function with the one we just created
  // std::array<char, sizeof(RED4ext::CClassFunction)> tmpBuffer;

  // std::memcpy(&tmpBuffer, TppCameraParamsOld,
  // sizeof(RED4ext::CClassFunction)); std::memcpy(TppCameraParamsOld,
  // TppCameraParamsNew, sizeof(RED4ext::CClassFunction));
  // std::memcpy(TppCameraParamsNew, &tmpBuffer,
  // sizeof(RED4ext::CClassFunction));

  // gamedataVehicle_Record->RegisterFunction(TppCameraParamsNew);
  // auto TppCameraParamsHandleFunc =
  // RED4ext::CClassFunction::Create(gamedataVehicle_Record,
  // "TppCameraParamsHandle", "TppCameraParamsHandle", &TppCameraParamsHandle, {
  // .isNative = true });
  // gamedataVehicle_Record->RegisterFunction(TppCameraParamsHandleFunc);

  // auto UIGameContextEnum = rtti->GetEnum("HUDActorType");
  // UIGameContextEnum->hashList.PushBack("FLIGHT");
  // UIGameContextEnum->valueList.PushBack(7);

  // RED4ext::CEnum::Flags flags = {};
  // RED4ext::CEnum gamePSMVehicleEnum = RED4ext::CEnum::CEnum("gamePSMVehicle",
  // 10, flags);

  // rtti->CreateScriptedEnum("gamePSMVehicle", 10, &gamePSMVehicleEnum);

  /*   auto cc = rtti->GetClass("vehicleTPPCameraComponent");
     cc->props.PushBack(RED4ext::CProperty::Create(
          rtti->GetType("Bool"), "isInAir", nullptr, 0x2E0));*/
  auto cc = rtti->GetClass("vehicleTPPCameraComponent");
  cc->props.PushBack(
      RED4ext::CProperty::Create(rtti->GetType("Float"), "drivingDirectionCompensationSpeedCoef", nullptr, 0x4E0));
  cc->props.PushBack(
      RED4ext::CProperty::Create(rtti->GetType("Float"), "drivingDirectionCompensationAngleSmooth", nullptr, 0x4E8));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "lockedCamera", nullptr, 0x48A));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("WorldPosition"), "worldPosition", nullptr, 0x320));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("WorldTransform"), "worldTransform2", nullptr, 0x2B0));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "pitch", nullptr, 0x380));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "yaw", nullptr, 0x384));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "yawDelta", nullptr, 0x2D0));
  cc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "pitchDelta", nullptr, 0x2D4));

  auto vbc = rtti->GetClass("vehicleBaseObject");
  vbc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "isOnGround", nullptr, 0x24C));
  // vbc->props.PushBack(RED4ext::CProperty::Create(
  //  rtti->GetType("WorldTransform"), "unkWorldTransform", nullptr, 0x330));
  // vbc->props.PushBack(RED4ext::CProperty::Create(
  //  rtti->GetType("handle:entIPlacedComponent"), "chassis", nullptr, 0x2D0));
  auto getInertiaTensor = RED4ext::CClassFunction::Create(vbc, "GetInertiaTensor", "GetInertiaTensor",
                                                          &VehicleGetInertiaTensor, {.isNative = true});
  vbc->RegisterFunction(getInertiaTensor);

  auto getMomentOfInertiaScale = RED4ext::CClassFunction::Create(vbc, "GetMomentOfInertiaScale", "GetMomentOfInertiaScale",
                                                          &VehicleGetMomentOfInertiaScale, {.isNative = true});
  vbc->RegisterFunction(getMomentOfInertiaScale);

  auto usesInertiaTensor = RED4ext::CClassFunction::Create(vbc, "UsesInertiaTensor", "UsesInertiaTensor",
                                                          &VehicleUsesInertiaTensor, {.isNative = true});
  vbc->RegisterFunction(usesInertiaTensor);

  auto getCenterOfMass = RED4ext::CClassFunction::Create(vbc, "GetCenterOfMass", "GetCenterOfMass",
                                                         &VehicleGetCenterOfMass, {.isNative = true});
  vbc->RegisterFunction(getCenterOfMass);

  auto getAngularVelocity = RED4ext::CClassFunction::Create(vbc, "GetAngularVelocity", "GetAngularVelocity",
                                                         &VehicleGetAngularVelocity, {.isNative = true});
  vbc->RegisterFunction(getAngularVelocity);
  
  auto turnOffAirControl = RED4ext::CClassFunction::Create(vbc, "TurnOffAirControl", "TurnOffAirControl", &VehicleTurnOffAirControl, {.isNative = true});
  vbc->RegisterFunction(turnOffAirControl);


  auto ms = rtti->GetClass("gameuiMinimapContainerController");
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "questPoints", nullptr, 0x1E0));
  ms->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("array:Vector4"), "playerPoints", nullptr, 0x208));

  auto vcc = rtti->GetClass("vehicleChassisComponent");
  auto getComOffsetFunc =
      RED4ext::CClassFunction::Create(vcc, "GetComOffset", "GetComOffset", &ChassisGetComOffset, {.isNative = true});
  vcc->RegisterFunction(getComOffsetFunc);

  auto vdtpe = rtti->GetClass("vehicleDriveToPointEvent");
  vdtpe->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Vector3"), "targetPos", nullptr, 0x40));
  vdtpe->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Bool"), "useTraffic", nullptr, 0x50));
  vdtpe->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "speedInTraffic", nullptr, 0x54));

  RED4ext::CRTTISystem::Get()->RegisterScriptName("entEffectSpawnerComponent", "EffectSpawnerComponent");
  auto eesc = rtti->GetClass("entEffectSpawnerComponent");
  auto eescAddEffect =
      RED4ext::CClassFunction::Create(eesc, "AddEffect", "AddEffect", &EffectSpawnerAddEffect, {.isNative = true});
  eesc->RegisterFunction(eescAddEffect);

  auto ecc = rtti->GetClass("entColliderComponent");
  ecc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "mass", nullptr, 0x150));
  ecc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Float"), "massOverride", nullptr, 0x14C));
  ecc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Vector3"), "inertia", nullptr, 0x158));
  ecc->props.PushBack(RED4ext::CProperty::Create(rtti->GetType("Transform"), "comOffset", nullptr, 0x170));

  // using func_t = bool (*)(RED4ext::CBaseRTTIType*, int64_t,
  // RED4ext::ScriptInstance); RED4ext::RelocFunc<func_t> func(0x1400000);

  // 0x120 + 0x40 (ptr120, float*);
  // 0x14342E6C0
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::PluginHandle aHandle, RED4ext::EMainReason aReason,
                                        const RED4ext::Sdk *aSdk) {
  switch (aReason) {
  case RED4ext::EMainReason::Load: {
    // Attach hooks, register RTTI types, add custom states or initalize your
    // application. DO NOT try to access the game's memory at this point, it
    // is not initalized yet.

    Utils::CreateLogger();
    spdlog::info("Starting up");

    RED4ext::RTTIRegistrator::Add(RegisterTypes, PostRegisterTypes);

    RED4ext::GameState initState;
    initState.OnEnter = nullptr;
    initState.OnUpdate = nullptr;
    initState.OnExit = &FlightAudio::Load;

    aSdk->gameStates->Add(aHandle, RED4ext::EGameStateType::Initialization, &initState);

    RED4ext::GameState shutdownState;
    shutdownState.OnEnter = nullptr;
    shutdownState.OnUpdate = &FlightAudio::Unload;
    shutdownState.OnExit = nullptr;

    aSdk->gameStates->Add(aHandle, RED4ext::EGameStateType::Shutdown, &shutdownState);

    aSdk->hooking->Attach(aHandle,
                          RED4EXT_OFFSET_TO_ADDR(RED4ext::Addresses::VehiclePhysicsApplyForceTorque),
                          &PhysicsStructUpdate, reinterpret_cast<void **>(&PhysicsStructUpdate_Original));
    break;
  }
  case RED4ext::EMainReason::Unload: {
    // Free memory, detach hooks.
    // The game's memory is already freed, to not try to do anything with it.

    spdlog::info("Shutting down");
    aSdk->hooking->Detach(aHandle,
                          RED4EXT_OFFSET_TO_ADDR(RED4ext::Addresses::VehiclePhysicsApplyForceTorque));
    spdlog::shutdown();
    break;
  }
  }

  return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo *aInfo) {
  aInfo->name = L"Flight Control";
  aInfo->author = L"Jack Humbert";
  aInfo->version = RED4EXT_SEMVER(0, 0, 2);
  aInfo->runtime = RED4EXT_RUNTIME_LATEST;
  aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports() { return RED4EXT_API_VERSION_LATEST; }
