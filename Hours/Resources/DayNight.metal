#include <metal_stdlib>
using namespace metal;
struct Uniforms { float4 sun; float4 viewport; float4 style; };
struct Vertex { float4 position [[position]]; float2 uv; };
vertex Vertex nightVertex(uint id [[vertex_id]]) {
    float2 p = float2((id << 1) & 2, id & 2);
    return {float4(p * float2(2, -2) + float2(-1, 1), 0, 1), p};
}
fragment float4 nightFragment(Vertex in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
    float2 map = u.viewport.xy + in.uv * u.viewport.zw;
    if (map.y < 0 || map.y > 1) return float4(0);
    // fract makes -180 and +180 the same meridian, including after rebasing.
    float longitude = (fract(map.x) - 0.5f) * 2.0f * M_PI_F;
    float mercator = M_PI_F * (1.0f - 2.0f * map.y);
    float cosLatitude = 1.0f / cosh(mercator);
    float3 normal = float3(cosLatitude * cos(longitude), cosLatitude * sin(longitude), tanh(mercator));
    float elevation = asin(clamp(dot(normal, u.sun.xyz), -1.0f, 1.0f)) * (180.0f / M_PI_F);
    float amount = smoothstep(0.0f, u.style.y, -elevation) * u.style.x;
    // Premultiplied black, float alpha; no 8-bit alpha contours or bitmap uploads.
    return float4(0, 0, 0, amount);
}

struct LightData { float4 positionAndVisibility; };
struct LightUniforms { float4 viewport; float4 color; };
struct LightVertex {
    float4 position [[position]];
    float2 local;
    float4 color;
};
vertex LightVertex cityLightVertex(uint vertexID [[vertex_id]], uint instance [[instance_id]],
                                  constant Uniforms &u [[buffer(0)]],
                                  const device LightData *lights [[buffer(1)]],
                                  constant LightUniforms &a [[buffer(2)]]) {
    uint copies = uint(ceil(u.viewport.z)) + 2;
    LightData light = lights[instance / copies];
    float cycle = floor(u.viewport.x - light.positionAndVisibility.x) + float(instance % copies);
    float2 point = (light.positionAndVisibility.xy + float2(cycle, 0) - u.viewport.xy) / u.viewport.zw * a.viewport.xy;
    const float2 corners[] = {float2(-1,-1), float2(1,-1), float2(-1,1),
                             float2(-1,1), float2(1,-1), float2(1,1)};
    // The immutable Figma sprite already includes core, glow and blur padding.
    float2 local = corners[vertexID] * (a.viewport.z * 0.5f);
    float2 uv = (point + local) / a.viewport.xy;
    float alpha = light.positionAndVisibility.z * a.color.a;
    return {float4(uv * float2(2,-2) + float2(-1,1), 0, 1), corners[vertexID] * 0.5f + 0.5f, float4(a.color.rgb, alpha)};
}
fragment float4 cityLightFragment(LightVertex in [[stage_in]], texture2d<float> sprite [[texture(0)]]) {
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    // Premultiplied source-over; selectedInstant controls the entire light's fade.
    return sprite.sample(linearSampler, in.local) * in.color.a;
}
