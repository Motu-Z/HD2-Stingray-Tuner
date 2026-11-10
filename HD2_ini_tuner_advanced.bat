@echo off
chcp 936 >nul 2>&1
title Helldivers 2 settings.ini tuner (advanced)
setlocal
set "HD2_SELF=%~f0"
set "HD2_ARG=%~1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$b=[IO.File]::ReadAllBytes($env:HD2_SELF); if($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF){ $t=[Text.Encoding]::UTF8.GetString($b,3,$b.Length-3) } else { try { $t=(New-Object System.Text.UTF8Encoding($false,$true)).GetString($b) } catch { $t=[Text.Encoding]::GetEncoding(936).GetString($b) } }; $i=$t.LastIndexOf('#PS-BEGIN#'); if($i -lt 0){Write-Host 'marker missing';exit 1}; iex $t.Substring($i)"
set "HD2_RC=%ERRORLEVEL%"
echo.
pause
endlocal & exit /b %HD2_RC%
#PS-BEGIN#
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::GetEncoding(936)
$OutputEncoding=[Text.Encoding]::GetEncoding(936)
$Latin=[Text.Encoding]::GetEncoding(28591)

# ===== 配置区 =====
# Tier: SAFE=安全  TRADEOFF=画质换性能  HWSPEC=按硬件  CAUTION=谨慎
# Src : 通用=与硬件无关的引擎层值 / 按硬件=按本机检测结果推算 / 按目标=取决于要画质还是帧数
# Conf: 确定=公开文档或可确证机制 / 推定=引擎模型推断 / 推测=按命名与方向推断 / 猜测=判定逻辑未知
# Suggest 只是参考值来源，不绑定任何特定机器；定义写在 Note，只在逐项修改或查详情时展开。
$Params=@(
 [pscustomobject]@{Key='num_reserved_threads';Default='2';Suggest='18';Tier='HWSPEC';Rule='threads';Src='按硬件';Impact='CPU·并行';Conf='推定';Cond='仅双CCD且已用CPU Sets/BIOS绑定单CCD时才需要改';Note='线程池保留线程数。引擎作业线程数 = 逻辑处理器总数 − 此值，32 逻辑核时 2 对应 30 条、18 对应 14 条。影响 CPU 并行吞吐与 fork-join 尾延迟；仅双 CCD 且已用 CPU Sets 绑定单 CCD 时才需要调高。'}
 [pscustomobject]@{Key='memory_budget_mb';Default='1536';Suggest='3072';Tier='HWSPEC';Rule='membudget';Src='按硬件';Impact='显存·驻留↑';Conf='推定';Cond='显存充足且系统盘为SSD时';Note='流送纹理常驻 mip 数据量目标，MB。调高提升纹理清晰度、减少反复载入，代价是显存驻留上升；超过显存会引发频繁驱逐并严重掉帧。'}
 [pscustomobject]@{Key='texture_heap_usage_limit';Default='5376';Suggest='6144';Tier='HWSPEC';Rule='heap';Src='按硬件';Impact='显存·上限';Conf='推定';Cond='必须匹配显存';Note='D3D12 纹理堆驻留上限，MB。决定纹理可申请的显存堆大小；超过物理显存会退化到共享内存，帧数灾难性下降。'}
 [pscustomobject]@{Key='hdr_enabled';Default='false';Suggest='false';Tier='HWSPEC';Rule='hdr';Src='按硬件';Impact='画质·色彩';Conf='确定';Cond='仅显示器支持HDR且已在Windows开启HDR时';Note='HDR 输出开关。需显示器与 Windows HDR 同时支持；开错会色彩发灰、亮度异常。工具不自动开。'}
 [pscustomobject]@{Key='prefer_hdr';Default='false';Suggest='false';Tier='HWSPEC';Rule='hdr';Src='按硬件';Impact='画质·色彩';Conf='确定';Cond='同上';Note='HDR 偏好开关，与 hdr_enabled 必须一致。不一致可能导致 HDR 判定混乱。'}
 [pscustomobject]@{Key='minimum_unload_delay';Default='2';Suggest='30';Tier='SAFE';Rule='delay';Src='按硬件';Impact='显存·驻留↑';Conf='推测';Cond='通用';Note='纹理最短驻留时间，单位推断为秒。延长可抑制反复驱逐/重载，减少帧时间抖动，代价是显存常驻量上升。'}
 [pscustomobject]@{Key='minimum_shrink_delay';Default='30';Suggest='90';Tier='SAFE';Rule='delay';Src='按硬件';Impact='显存·抖动↓';Conf='推测';Cond='通用';Note='流送池收缩前的等待时长。延长减少池重分配与抖动，代价是显存回收变慢。'}
 [pscustomobject]@{Key='max_frame_copy_bytes';Default='67108864';Suggest='100663296';Tier='SAFE';Rule='copyband';Src='按硬件';Impact='显存·拷贝';Conf='推测';Cond='通用';Note='单帧 GPU 内拷贝上限，字节，走显存带宽。通常不是瓶颈；放宽对帧数影响有限，小显存机器可能放大单帧压力。'}
 [pscustomobject]@{Key='max_frame_upload_bytes';Default='16777216';Suggest='16777216';Tier='SAFE';Rule='keep';Src='通用';Impact='帧时间·尖峰';Conf='推定';Cond='不建议改';Note='单帧 CPU→GPU 上传上限，16MB，走 PCIe。这是防抖动的节流阀，放宽只会放大单帧 PCIe 尖峰，不建议改。'}
 [pscustomobject]@{Key='pipeline_cache_prune_size';Default='256';Suggest='512';Tier='SAFE';Rule='keep';Src='通用';Impact='帧时间·编译卡顿';Conf='推测';Cond='通用';Note='管线缓存裁剪阈值。调大减少着色器重编译造成的卡顿，代价是缓存文件变大、磁盘占用上升。'}
 [pscustomobject]@{Key='pso_cache_prune_size';Default='512';Suggest='1024';Tier='SAFE';Rule='keep';Src='通用';Impact='帧时间·编译卡顿';Conf='推测';Cond='通用';Note='PSO blob 缓存裁剪阈值，同上。'}
 [pscustomobject]@{Key='anti_lag';Default='true';Suggest='false';Tier='SAFE';Rule='keep';Src='通用';Impact='延迟·帧节奏';Conf='推定';Cond='已启用Reflex的N卡';Note='引擎侧帧节奏控制。与 NVIDIA Reflex 功能重叠，两套同时开会争抢帧提交节奏；已开 Reflex 时建议关。'}
 [pscustomobject]@{Key='memory_size';Default='26214400';Suggest='78643200';Tier='SAFE';Rule='wwisepool';Src='按硬件';Impact='音频·缓冲';Conf='确定';Cond='物理内存16GB以上且系统盘为SSD';Note='Wwise 流式 IO 缓冲池字节数，对应 AkDeviceSettings::uIOMemorySize。块数 = 此值 / granularity，出厂 25MB/128KB = 200 块。影响音频预读能力，不直接改帧数。'}
 [pscustomobject]@{Key='max_concurrent_io';Default='200';Suggest='200';Tier='SAFE';Rule='ioconcurrent';Src='按硬件';Impact='音频·IO';Conf='确定';Cond='不建议改';Note='Wwise 并发 IO 请求数，对应 uMaxConcurrentIO；SDK 默认 8，出厂 200 与出厂缓冲块数配套。降并发未验证有效。'}
 [pscustomobject]@{Key='verbose';Default='true';Suggest='false';Tier='SAFE';Rule='keep';Src='通用';Impact='磁盘·写日志';Conf='推定';Cond='通用';Note='EOS 详细日志开关。开启会持续写盘，产生额外磁盘 IO；关闭对帧数影响很小，主要是减少日志噪音。'}
 [pscustomobject]@{Key='use_syncapi';Default='true';Suggest='true';Tier='SAFE';Rule='keep';Src='通用';Impact='CPU·空闲';Conf='推定';Cond='不建议改';Note='线程池空闲时用阻塞等待代替自旋。降低空闲 CPU 占用，忙时无差异。'}
 [pscustomobject]@{Key='command_queue_size';Default='524288';Suggest='524288';Tier='SAFE';Rule='keep';Src='通用';Impact='音频·命令';Conf='确定';Cond='不建议改';Note='Wwise 音频命令队列字节数，对应 uCommandQueueSize，出厂 512KB 已是 SDK 默认 2 倍。队列满会丢音频命令，出厂已宽裕。'}
 [pscustomobject]@{Key='pool_size';Default='33554432';Suggest='33554432';Tier='SAFE';Rule='keep';Src='通用';Impact='内存·音频池';Conf='确定';Cond='不建议改';Note='Wwise 声音引擎默认内存池，对应 uDefaultPoolSize，出厂 32MB 已是 SDK 默认 2 倍。影响可同时驻留的声音对象数量。'}
 [pscustomobject]@{Key='num_refills_in_voice';Default='4';Suggest='4';Tier='SAFE';Rule='keep';Src='通用';Impact='音频·缓冲';Conf='确定';Cond='不建议改';Note='流式声音缓冲补充次数，对应 uNumRefillsInVoice，SDK 默认 4。影响流式音频的缓冲深度与抗抖动能力。'}
 [pscustomobject]@{Key='memory_alignment';Default='64';Suggest='64';Tier='SAFE';Rule='keep';Src='通用';Impact='音频·IO对齐';Conf='确定';Cond='不建议改';Note='Wwise IO 内存对齐字节数，对应 uIOMemoryAlignment，出厂 64、SDK 默认 4。改动会影响 IO 请求对齐方式。'}
 [pscustomobject]@{Key='scratch_space';Default='128';Suggest='128';Tier='SAFE';Rule='keep';Src='通用';Impact='显存·上传缓冲';Conf='推定';Cond='不建议改';Note='D3D12 临时与上传缓冲区，MB。出厂 128MB 已宽裕，通常不是瓶颈；过小可能导致上传等待。'}
 [pscustomobject]@{Key='atmospheric_scattering_ambience_samples';Default='128';Suggest='64';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='GPU·画质↓帧↑';Conf='确定';Cond='GPU瓶颈且开放天空场景时';Note='环境散射积分采样数，等于 GPU 着色器循环次数。减半约线性降低该 pass 的 GPU 成本、提升帧数；画质可能出现色带或噪点。'}
 [pscustomobject]@{Key='sun_step_length_multiplier';Default='0.17';Suggest='0.4';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='GPU·画质↓帧↑';Conf='确定';Cond='GPU瓶颈且开放天空场景时';Note='朝太阳方向 ray-march 的步长缩放，步数与系数成反比。0.17→0.4 约把步数降到 42.5%，降低 GPU 成本；步长过大会出现条带伪影。'}
 [pscustomobject]@{Key='cloud_step_length';Default='8';Suggest='8';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='GPU·画质↓帧↑';Conf='推定';Cond='GPU瓶颈时自行加大步长';Note='体积云光线步进步长。加大减少步数、降低 GPU 成本；过大出现层状伪影。工具不自动改，只给方向。'}
 [pscustomobject]@{Key='realtime_cubemaps_nr_regular_samples';Default='32';Suggest='32';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='GPU·画质↓帧↑';Conf='推定';Cond='GPU瓶颈时自行减小';Note='实时反射 cubemap 常规采样数。减小降低 GPU 成本，反射会变糊；同族还有 far/space/downsample 多组。'}
 [pscustomobject]@{Key='fullscreen';Default='false';Suggest='false';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='延迟·合成';Conf='确定';Cond='与borderless_fullscreen必须一真一假';Note='独占全屏开关。绕过 DWM 合成，延迟更低、Reflex 完整生效；代价是 alt-tab 变慢、部分 overlay 异常。与 borderless_fullscreen 必须一真一假。'}
 [pscustomobject]@{Key='borderless_fullscreen';Default='true';Suggest='true';Tier='TRADEOFF';Rule='keep';Src='按目标';Impact='延迟·合成';Conf='确定';Cond='与fullscreen必须一真一假';Note='无边框全屏开关，经 DWM 合成，额外一帧延迟。改 fullscreen 时本项需同步取反，否则组合非法。'}
 [pscustomobject]@{Key='max_frame_updates';Default='32';Suggest='64';Tier='CAUTION';Rule='frameupdates';Src='通用';Impact='帧时间·尖峰';Conf='推定';Cond='仅在确认纹理加载慢且帧时间有余量时试';Note='单帧允许处理的流送更新条数。翻倍会放大渲染线程偶发尖峰，通常得不偿失；仅在确认纹理加载慢且帧时间有余量时试。'}
 [pscustomobject]@{Key='granularity';Default='131072';Suggest='131072';Tier='CAUTION';Rule='keep';Src='通用';Impact='音频·IO块';Conf='确定';Cond='不建议单独改';Note='Wwise 单次 IO 请求字节数，对应 uGranularity，出厂 128KB、SDK 默认 16KB。改它会破坏 memory_size / max_concurrent_io 的块数配套。'}
 [pscustomobject]@{Key='target_buffering_length';Default='720';Suggest='720';Tier='CAUTION';Rule='keep';Src='通用';Impact='音频·预读';Conf='确定';Cond='不建议单独改';Note='Wwise 目标预读缓冲，对应 fTargetAutoStmBufferLength，单位毫秒。调大必须同步加大 memory_size，否则目标不可达。'}
 [pscustomobject]@{Key='use_blocking_io';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='CPU·音频线程';Conf='确定';Cond='不建议改';Note='Wwise IO 调度模式，false 为 deferred。切 true 会退化为阻塞式调度并额外拉线程，增加 CPU 占用。'}
 [pscustomobject]@{Key='num_samples_per_frame';Default='1024';Suggest='1024';Tier='CAUTION';Rule='keep';Src='通用';Impact='音频·延迟';Conf='确定';Cond='仅在音频畸变且排除链路问题后';Note='音频渲染每块样本数，对应 uNumSamplesPerFrame；1024 在 48kHz 约 21.3ms。改 2048 是掩盖型手段，代价是音频延迟 +21ms，不解决链路问题。'}
 [pscustomobject]@{Key='max_cache_ratio';Default='1';Suggest='1';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='Wwise 缓存占比上限，对应 fMaxCacheRatio。判定逻辑没有可靠公开说明，改动后果未知。'}
 [pscustomobject]@{Key='reflex_mode';Default='2';Suggest='2';Tier='CAUTION';Rule='reflex';Src='按硬件';Impact='延迟·CPU提交';Conf='确定';Cond='N卡且已开Reflex时';Note='NVIDIA Reflex 模式，2 = On + Boost，限制 CPU 提前提交的帧数以降低延迟。非 N 卡该项无意义。'}
 [pscustomobject]@{Key='vsync';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='延迟·同步';Conf='确定';Cond='高刷屏用VRR+帧率上限替代';Note='垂直同步开关。无边框下关 vsync 拿不到低延迟，仍受 DWM 刷新率同步；高刷屏建议用 VRR + 帧率上限替代。'}
 [pscustomobject]@{Key='adapter_index';Default='0';Suggest='0';Tier='CAUTION';Rule='adapter';Src='按硬件';Impact='GPU·适配器';Conf='确定';Cond='有集显的笔记本需先确认枚举顺序';Note='D3D 适配器索引。有集显的笔记本（如 9955HX 自带 Radeon 610M）索引 0 若指向集显，会让整套调优失效。需先确认枚举顺序。'}
 [pscustomobject]@{Key='d3d_debug';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='帧数·灾难↓';Conf='确定';Cond='绝不开';Note='D3D 调试层开关。开启会灾难性降速，绝不用于正常游戏。'}
 [pscustomobject]@{Key='drs_minimum_scale_factor';Default='0.5';Suggest='0.5';Tier='CAUTION';Rule='keep';Src='通用';Impact='画质↓帧↑';Conf='推定';Cond='实际开关在user_settings.config';Note='动态分辨率下限比例。实际开关在 user_settings.config，settings.ini 这段可能被用户配置覆盖，改了未必生效。'}
 [pscustomobject]@{Key='max_num_jobs';Default='8192';Suggest='8192';Tier='CAUTION';Rule='keep';Src='通用';Impact='CPU·队列';Conf='推定';Cond='不建议改';Note='作业队列容量上限，不是并发度。8192 在 14 条 worker 上不会成为瓶颈。'}
 [pscustomobject]@{Key='metrics_batch_timer';Default='30';Suggest='30';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='猜测';Cond='未验证开销';Note='遥测批量上报周期，单位推测为秒。无证据表明它造成周期性帧时间尖峰。'}
 [pscustomobject]@{Key='minimum_unseen_delay';Default='60';Suggest='60';Tier='CAUTION';Rule='keep';Src='通用';Impact='显存·卸载';Conf='猜测';Cond='判定逻辑未知';Note='纹理未被看见多久后进入卸载候选。具体判定未公开，改动后果未知。'}
 [pscustomobject]@{Key='inv_texel_density';Default='4';Suggest='4';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='纹素密度相关项。无可靠来源说明其判定与单位，别动。'}
 [pscustomobject]@{Key='max_mip';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='流送 mip 上限。无可靠来源说明取值语义，别动。'}
 [pscustomobject]@{Key='memory_threshold_fast_shrink';Default='33554432';Suggest='33554432';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='推测';Cond='判定逻辑未知';Note='触发流送池快速收缩的内存阈值，出厂 32MB。命名可推方向，具体判定未公开。'}
 [pscustomobject]@{Key='initialize_at_max';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='显存·首帧';Conf='推测';Cond='不建议改';Note='是否按最高 mip 初始化纹理。改动会改变首次加载行为与首帧显存占用。'}
 [pscustomobject]@{Key='streaming_update_quick_drops';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='流送更新快速丢弃开关。判定逻辑未公开，改动后果未知。'}
 [pscustomobject]@{Key='drop_dynamic_textures_on_renderer_reload';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='通用';Impact='画质·重载';Conf='推测';Cond='不建议改';Note='渲染器重载时是否丢弃动态纹理。改动可能引发重载后纹理缺失。'}
 [pscustomobject]@{Key='streaming_texture_pool_size';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='通用';Impact='显存·池';Conf='确定';Cond='不建议改';Note='Stingray 官方段：可流送纹理共享内存上限，MB，官方默认 256。置 0 表示由 texture_streaming 扩展段接管；填非 0 会与扩展段冲突。'}
 [pscustomobject]@{Key='streaming_buffer_size';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='通用';Impact='内存·载入';Conf='确定';Cond='不建议改';Note='Stingray 官方段：从磁盘载入新纹理的缓冲，MB，官方默认 24。置 0 表示由扩展段接管。'}
 [pscustomobject]@{Key='max_num_jobs_data_dir';Default='32768';Suggest='32768';Tier='CAUTION';Rule='keep';Src='通用';Impact='CPU·加载队列';Conf='推定';Cond='不建议改';Note='数据目录加载阶段的作业队列容量上限，不是并发度。'}
)
# ===== 配置区结束 =====


$TierTag=@{SAFE='[安全]';TRADEOFF='[画质换性能]';HWSPEC='[按硬件]';CAUTION='[谨慎]'}
$TierOrder=@('SAFE','TRADEOFF','HWSPEC','CAUTION')
$Protected=@('dearimgui_enabled','crash_dump','floating_point_exceptions')

function Pad([string]$s,[int]$w){
  if($null -eq $s){ $s='' }
  $cw=0
  foreach($ch in $s.ToCharArray()){ if([int]$ch -gt 127){$cw+=2}else{$cw+=1} }
  if($cw -ge $w){ return $s }
  return $s + (' '*($w-$cw))
}

function Get-IniText([string]$p){ $Latin.GetString([IO.File]::ReadAllBytes($p)) }
function Get-Raw([string]$p){ return [IO.File]::ReadAllBytes($p) }

function Get-Val([string]$t,[string]$k){
  $e=[regex]::Escape($k)
  $m=[regex]::Match($t,'(?m)^[ \t]*'+$e+'[ \t]*=[ \t]*([^/\r\n]*?)([ \t]*//[^\r\n]*)?(?=\r|\n|$)')
  if($m.Success){ return $m.Groups[1].Value.Trim() }
  return $null
}

function Set-Val([string]$t,[string]$k,[string]$v){
  $e=[regex]::Escape($k)
  $p='(?m)^([ \t]*'+$e+'[ \t]*=[ \t]*)([^/\r\n]*?)([ \t]*//[^\r\n]*)?(?=\r|\n|$)'
  $cnt=[regex]::Matches($t,$p).Count
  $safe=$v.Replace('$','$$')
  $rep='${1}'+$safe+'${3}'
  $out=[regex]::Replace($t,$p,$rep)
  return @{Text=$out;Count=$cnt}
}

# 按出厂值推断该键类型，用于拒绝把非法值写进 ini
function Get-ValType([string]$d){
  if($d -match '^(true|false)$'){ return 'bool' }
  if($d -match '^-?\d+$'){ return 'int' }
  if($d -match '^-?\d*\.\d+$'){ return 'float' }
  return 'string'
}
function Test-Val([string]$v,[string]$d){
  $t=Get-ValType $d
  switch($t){
    'bool'  { return ($v -cmatch '^(true|false)$') }
    'int'   { return ($v -match '^-?\d+$') }
    'float' { return ($v -match '^-?\d*\.?\d+$') }
    default { return $true }
  }
}

function Get-DuplicateKeys([string]$t){
  $r=@()
  foreach($p in $Params){
    $e=[regex]::Escape($p.Key)
    $n=[regex]::Matches($t,'(?m)^[ \t]*'+$e+'[ \t]*=').Count
    if($n -gt 1){ $r+=[pscustomobject]@{Key=$p.Key;Count=$n} }
  }
  return $r
}

function Get-ComboWarnings([string]$t){
  $w=@()
  $f=Get-Val $t 'fullscreen'; $b=Get-Val $t 'borderless_fullscreen'
  if($f -and $b -and ($f -eq $b)){
    $w+=("fullscreen 与 borderless_fullscreen 同为 {0}，组合非法。两者必须一真一假。" -f $f)
  }
  $h=Get-Val $t 'hdr_enabled'; $ph=Get-Val $t 'prefer_hdr'
  if($h -and $ph -and ($h -ne $ph)){ $w+='hdr_enabled 与 prefer_hdr 不一致，可能导致HDR判定混乱。' }
  return $w
}

function Get-ByteDiff([byte[]]$a,[byte[]]$b){
  # 按行比对：值的长度一变，逐位置比较会让后面整片字节错位，行数才是准确的改动范围
  $sa=$Latin.GetString($a); $sb=$Latin.GetString($b)
  $la=$sa -split "`n"; $lb=$sb -split "`n"
  $n=[Math]::Max($la.Count,$lb.Count)
  $lines=0; $firstLine=-1; $lastLine=-1; $nums=@()
  for($i=0;$i -lt $n;$i++){
    $xa=if($i -lt $la.Count){$la[$i]}else{$null}
    $xb=if($i -lt $lb.Count){$lb[$i]}else{$null}
    if($xa -cne $xb){
      $lines++
      if($firstLine -lt 0){ $firstLine=$i+1 }
      $lastLine=$i+1
      if($nums.Count -lt 12){ $nums+=($i+1) }
    }
  }
  $crlfA=0; $crlfB=0
  for($i=0;$i -lt $a.Length-1;$i++){ if($a[$i] -eq 13 -and $a[$i+1] -eq 10){$crlfA++} }
  for($i=0;$i -lt $b.Length-1;$i++){ if($b[$i] -eq 13 -and $b[$i+1] -eq 10){$crlfB++} }
  $bomA=($a.Length -ge 3 -and $a[0] -eq 0xEF -and $a[1] -eq 0xBB -and $a[2] -eq 0xBF)
  $bomB=($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
  $lineNums=if($lines -eq 0){ '无' }else{ ($nums -join ',') }
  return [pscustomobject]@{Lines=$lines;FirstLine=$firstLine;LastLine=$lastLine;LineNums=$lineNums;LenA=$a.Length;LenB=$b.Length;CRLF_A=$crlfA;CRLF_B=$crlfB;BOM_A=$bomA;BOM_B=$bomB}
}

function Find-Ini(){
  $a=$env:HD2_ARG
  if($a){ $a=$a.Trim().Trim('"'); if([IO.File]::Exists($a)){ return $a } }
  $c=@()
  foreach($d in [IO.DriveInfo]::GetDrives()){
    if($d.DriveType -ne 'Fixed'){ continue }
    $r=$d.RootDirectory.FullName
    $c += [IO.Path]::Combine($r,'Steam\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'SteamLibrary\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'Program Files (x86)\Steam\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'Games\Steam\steamapps\common\Helldivers 2\data\settings.ini')
  }
  $hit=@($c | Where-Object { [IO.File]::Exists($_) } | Select-Object -Unique)
  if($hit.Count -eq 1){ return $hit[0] }
  if($hit.Count -gt 1){
    Write-Host '找到多个 settings.ini：'
    for($i=0;$i -lt $hit.Count;$i++){ Write-Host ("  [{0}] {1}" -f ($i+1),$hit[$i]) }
    $s=Read-Host '输入编号，回车用第 1 个'
    if([string]::IsNullOrWhiteSpace($s)){ return $hit[0] }
    $n=0; if([int]::TryParse($s,[ref]$n) -and $n -ge 1 -and $n -le $hit.Count){ return $hit[$n-1] }
    Write-Host '编号无效，用第 1 个'; return $hit[0]
  }
  Write-Host '未自动找到 settings.ini。'
  $u=Read-Host '把文件拖进本窗口后回车，或直接粘贴完整路径'
  if([string]::IsNullOrWhiteSpace($u)){ return $null }
  $u=$u.Trim().Trim('"')
  if([IO.File]::Exists($u)){ return $u }
  Write-Host '路径不存在'; return $null
}

function New-Backup([string]$p){
  $dir=[IO.Path]::GetDirectoryName($p)
  $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak=[IO.Path]::Combine($dir,"settings.ini.bak-$stamp")
  $n=1
  while([IO.File]::Exists($bak)){ $n++; $bak=[IO.Path]::Combine($dir,"settings.ini.bak-$stamp-$n") }
  [IO.File]::Copy($p,$bak)
  return $bak
}

function Get-HW([string]$iniPath){
  $logical=[Environment]::ProcessorCount
  $physical=$logical
  $cpuName=''
  try {
    $cpus=@(Get-CimInstance Win32_Processor -ErrorAction Stop)
    if($cpus.Count -gt 0){
      $l=($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
      $ph=($cpus | Measure-Object -Property NumberOfCores -Sum).Sum
      if($l){ $logical=[int]$l }
      if($ph){ $physical=[int]$ph }
      $cpuName=[string]$cpus[0].Name
    }
  } catch {}
  $ram=0
  try { $cs=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if($cs.TotalPhysicalMemory){ $ram=[int]($cs.TotalPhysicalMemory/1MB) } } catch {}
  $vram=0; $gpu='未知'
  $cls='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
  try {
    foreach($s in @(Get-ChildItem $cls -ErrorAction SilentlyContinue)){
      $p=Get-ItemProperty $s.PSPath -ErrorAction SilentlyContinue
      if($p -and $p.'HardwareInformation.qwMemorySize'){
        $mb=[int64]$p.'HardwareInformation.qwMemorySize'/1MB
        if($mb -gt $vram){ $vram=[int]$mb; if($p.DriverDesc){ $gpu=[string]$p.DriverDesc } }
      }
    }
  } catch {}
  if($vram -eq 0){
    try { $vc=Get-CimInstance Win32_VideoController -ErrorAction Stop | Sort-Object AdapterRAM -Descending | Select-Object -First 1; if($vc){ $vram=[int]($vc.AdapterRAM/1MB); $gpu=[string]$vc.Name } } catch {}
  }
  $vendor='未知'
  if($gpu -match 'NVIDIA|GeForce|RTX|GTX'){ $vendor='NVIDIA' }
  elseif($gpu -match 'AMD|Radeon'){ $vendor='AMD' }
  elseif($gpu -match 'Intel|Arc|Iris'){ $vendor='Intel' }
  $disk='未知'
  try {
    $root=[IO.Path]::GetPathRoot([IO.Path]::GetFullPath($iniPath))
    $letter=$root.Substring(0,1)
    $pd=$null
    try {
      $part=Get-Partition -DriveLetter $letter -ErrorAction Stop
      $pd=@(Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq $part.DiskNumber } | Select-Object -First 1)
    } catch {}
    if(-not $pd -or $pd.Count -eq 0){ $pd=@(Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1) }
    if($pd.Count -gt 0){
      $bus=[string]$pd[0].BusType; $mt=[string]$pd[0].MediaType
      if($bus -match 'NVMe'){ $disk='NVMe SSD' }
      elseif($bus -match 'SATA' -and $mt -match 'SSD'){ $disk='SATA SSD' }
      elseif($mt -match 'HDD'){ $disk='HDD' }
      elseif($mt -match 'SSD'){ $disk='SSD' }
      else { $disk=("$bus/$mt").Trim('/') }
    }
  } catch { $disk='未知' }
  $laptop=$false
  try { if(@(Get-CimInstance Win32_Battery -ErrorAction Stop).Count -gt 0){ $laptop=$true } } catch {}
  # 双CCD只能靠型号字符串匹配，无可靠API，标记【推】，只用于提示文字，不改任何数值
  $dualCCD=$false
  if($cpuName -match '9950X|9955HX|7950X|7955HX|5950X|5900X|3950X|3900X|1920X|1950X|2990WX|2970WX'){ $dualCCD=$true }
  return [pscustomobject]@{Logical=$logical;Physical=$physical;RAM=$ram;VRAM=$vram;GPU=$gpu;Vendor=$vendor;Disk=$disk;Laptop=$laptop;CPUName=$cpuName;DualCCD=$dualCCD}
}

function Get-LocalSuggest([object]$p,[object]$hw){
  switch($p.Rule){
    'threads' {
      $ccd='未检测到双CCD型号'
      if($hw.DualCCD){ $ccd='型号匹配到疑似双CCD（【推】仅按名称匹配，不作准）' }
      return [pscustomobject]@{V='2';Why=("你本机 {0} 逻辑核，{1}。默认保持 2。仅当你已用 CPU Sets 或 BIOS 绑定单 CCD 时，才按 reserved = 逻辑核数 - 目标线程数 计算；例如 32 逻辑核绑 14 线程算得 18。未绑定请勿改。" -f $hw.Logical,$ccd)}
    }
    'membudget' {
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=("系统盘是机械盘，IO 抖动风险高，保持默认 {0}MB。" -f $p.Default)} }
      if($hw.VRAM -ge 12000){ return [pscustomobject]@{V='3072';Why=("显存约 {0}MB，可用 3072MB。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 8000){ return [pscustomobject]@{V='2048';Why=("显存约 {0}MB，建议 2048MB，避免挤压其他资源。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 6000){ return [pscustomobject]@{V='1792';Why=("显存约 {0}MB，建议 1792MB。" -f $hw.VRAM)} }
      else { return [pscustomobject]@{V=$p.Default;Why=("显存 {0}MB 或未检测到，保持默认 {1}。" -f $hw.VRAM,$p.Default)} }
    }
    'heap' {
      if($hw.VRAM -ge 16000){ return [pscustomobject]@{V='8192';Why=("显存约 {0}MB，可给 8192MB 堆上限。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 12000){ return [pscustomobject]@{V='6144';Why=("显存约 {0}MB，给 6144MB，约留 5-6GB 给其他资源。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 8000){ return [pscustomobject]@{V='4096';Why=("显存约 {0}MB，给 4096MB。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 6000){ return [pscustomobject]@{V='3072';Why=("显存约 {0}MB，给 3072MB。" -f $hw.VRAM)} }
      else { return [pscustomobject]@{V=$p.Default;Why=("显存 {0}MB 或未检测到，保持默认 {1}。" -f $hw.VRAM,$p.Default)} }
    }
    'wwisepool' {
      if($hw.RAM -le 0){ return [pscustomobject]@{V=$p.Default;Why=('物理内存未检测到（读取 Win32_ComputerSystem 失败），无法判断能否承受更大缓冲池，保守保持默认 25MB。')} }
      if($hw.RAM -lt 16000){ return [pscustomobject]@{V=$p.Default;Why=("物理内存约 {0}MB 偏小，保持默认 25MB 缓冲池。" -f $hw.RAM)} }
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=('系统盘是机械盘，并发读争抢风险高，保持默认 25MB。')} }
      if($hw.Disk -eq '未知'){ return [pscustomobject]@{V=$p.Default;Why=('系统盘类型未检测到，无法确认是否为 SSD，保守保持默认 25MB。')} }
      return [pscustomobject]@{V='78643200';Why=('内存充足且为SSD，给 75MB（600块@128KB），让 720ms 预读目标可达。')}
    }
    'ioconcurrent' {
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=('机械盘上 200 并发读可能加重争抢，但降并发未验证有效，保持默认。')} }
      return [pscustomobject]@{V=$p.Default;Why=('出厂 200 与出厂缓冲块数配套，降并发未验证有效，保持默认。')}
    }
    'reflex' {
      if($hw.Vendor -ne 'NVIDIA'){ return [pscustomobject]@{V=$p.Default;Why=("GPU 厂商 {0}，Reflex 不适用，保持默认。" -f $hw.Vendor)} }
      return [pscustomobject]@{V='2';Why=('NVIDIA 显卡，2=On+Boost，保持默认即可。')}
    }
    'hdr' {
      return [pscustomobject]@{V=$p.Default;Why=('需按显示器 HDR 支持与 Windows HDR 开关手动决定，脚本不自动开。')}
    }
    'frameupdates' {
      return [pscustomobject]@{V='32';Why='保持默认 32。翻倍会放大渲染线程单帧尖峰，通常得不偿失；仅在确认纹理加载慢且帧时间有余量时再试 64。'}
    }
    'delay' {
      if($hw.VRAM -le 0){ return [pscustomobject]@{V=$p.Default;Why='显存未检测到，保守保持出厂默认。'} }
      if($hw.VRAM -ge 10000){ return [pscustomobject]@{V=$p.Suggest;Why=("显存约 {0}MB，延长驻留/收缩等待可减少纹理反复驱逐；【推测】按显存余量判断，非实测。" -f $hw.VRAM)} }
      return [pscustomobject]@{V=$p.Default;Why=("显存约 {0}MB，余量有限，保持出厂默认，避免常驻 mip 挤占其他资源。" -f $hw.VRAM)}
    }
    'copyband' {
      if($hw.VRAM -le 0){ return [pscustomobject]@{V=$p.Default;Why='显存未检测到，保持出厂默认 64MB。'} }
      if($hw.VRAM -ge 10000){ return [pscustomobject]@{V=$p.Suggest;Why=("显存约 {0}MB，可放宽单帧 GPU 内拷贝预算；【推测】拷贝走显存带宽，通常不是瓶颈。" -f $hw.VRAM)} }
      return [pscustomobject]@{V=$p.Default;Why=("显存约 {0}MB，保持出厂默认 64MB，避免小显存机器放大单帧拷贝压力。" -f $hw.VRAM)}
    }
    'adapter' {
      $hasIGPU=($hw.CPUName -match 'AMD|Intel') -and ($hw.Vendor -eq 'NVIDIA')
      if($hasIGPU){ return [pscustomobject]@{V=$p.Default;Why=('CPU 平台可能带集显且独显为 {0}，索引 0 有可能指向集显。保持默认，先确认 D3D 枚举顺序再改。' -f $hw.Vendor)} }
      return [pscustomobject]@{V=$p.Default;Why='保持默认 0。双显卡机器需自行确认 D3D 枚举顺序。'}
    }
    default {
      if($p.Src -eq '按目标'){ return [pscustomobject]@{V=$p.Suggest;Why='参考值代表一种画质/帧数取向。要画质还是要帧数由你定，工具不替你选；不想降画质就保持出厂值。'} }
      return [pscustomobject]@{V=$p.Suggest;Why='引擎层通用参考值，与本机硬件无关。是否采用看你自己的取舍。'}
    }
  }
}

function Show-Warnings([array]$dups,[array]$combos){
  if($dups.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 同名键 ===='
    Write-Host 'SJSON 里同名键后者覆盖前者。写入时脚本会把它们全部统一：'
    foreach($d in $dups){ Write-Host ("  {0} 出现 {1} 处" -f $d.Key,$d.Count) }
  }
  if($combos.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 组合冲突 ===='
    foreach($w in $combos){ Write-Host ("  {0}" -f $w) }
  }
}

function Confirm-Write([array]$changes,[string]$ctx){
  if($changes.Count -eq 0){ Write-Host '没有需要修改的项，未写入。'; return $false }
  Write-Host ''
  Write-Host '将要修改：'
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad $c.From 14),$c.To) }
  $risky=@($changes | Where-Object { $_.Tier -eq 'HWSPEC' -or $_.Tier -eq 'CAUTION' })
  $trade=@($changes | Where-Object { $_.Tier -eq 'TRADEOFF' })
  if($trade.Count -gt 0){
    Write-Host ''
    Write-Host ("提示: 含 {0} 项 [画质换性能]，会降画质换帧率，不想降画质就取消。" -f $trade.Count)
    foreach($t in $trade){ Write-Host ("  - {0}: {1}" -f $t.Key,$t.Cond) }
  }
  if($risky.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 高风险改动 ===='
    Write-Host ("  本次含 {0} 项 [按硬件]/[谨慎]。数值与硬件强相关，照抄可能掉帧、破音或触发驱动错误：" -f $risky.Count)
    foreach($r in $risky){ Write-Host ("  - {0}: {1}" -f $r.Key,$r.Cond) }
    Write-Host '  条件见各项的「适用条件」。这些项不进批量套用。'
    $ans=Read-Host '  输入 yes 继续，其它取消'
    return ($ans -eq 'yes')
  }
  $ok=Read-Host '确认写入? y/N'
  return ($ok -eq 'y')
}

function Apply-Changes([string]$path,[string]$text,[array]$changes){
  $rawA=Get-Raw $path
  $bak=New-Backup $path
  Write-Host ("备份: {0}" -f [IO.Path]::GetFileName($bak))
  $new=$text; $miss=@(); $dupFix=@()
  foreach($c in $changes){
    $r=Set-Val $new $c.Key $c.To
    if($r.Count -eq 0){ $miss+=$c.Key; continue }
    if($r.Count -gt 1){ $dupFix+=("{0}({1}处)" -f $c.Key,$r.Count) }
    $new=$r.Text
  }
  $combos=Get-ComboWarnings $new
  if($combos.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 写入后组合冲突 ===='
    foreach($w in $combos){ Write-Host ("  {0}" -f $w) }
    Write-Host '  这属于参数联动错误，建议从备份还原后成对修改。'
  }
  [IO.File]::WriteAllBytes($path,$Latin.GetBytes($new))
  $rawB=Get-Raw $path
  $d=Get-ByteDiff $rawA $rawB
  Write-Host ''
  Write-Host '写入完成，校验：'
  $chk=Get-IniText $path
  $bad=0
  foreach($c in $changes){
    if($miss -contains $c.Key){ Write-Host ("  [SKIP] {0} 文件中未找到该键，跳过" -f (Pad $c.Key 46)); continue }
    $v=Get-Val $chk $c.Key
    if($v -eq $c.To){ Write-Host ("  [OK]   {0} {1}" -f (Pad $c.Key 46),$v) }
    else{ Write-Host ("  [FAIL] {0} 期望 {1} 实际 {2}" -f (Pad $c.Key 46),$c.To,$v); $bad++ }
  }
  if($miss.Count -gt 0){ Write-Host ("  未找到，未修改: {0}" -f ($miss -join ', ')) }
  if($dupFix.Count -gt 0){ Write-Host ("  同名键已全部统一: {0}" -f ($dupFix -join ', ')) }
  if($bad -gt 0){ Write-Host ("  校验失败 {0} 项，建议从备份还原。" -f $bad) }
  else{ Write-Host '  已修改项全部校验通过。' }
  Write-Host ''
  Write-Host '==== 改动范围（按行比对）===='
  Write-Host ("  变化 {0} 行  行号 {1}  长度 {2} -> {3}" -f $d.Lines,$d.LineNums,$d.LenA,$d.LenB)
  Write-Host ("  CRLF {0} -> {1}  BOM {2} -> {3}" -f $d.CRLF_A,$d.CRLF_B,$d.BOM_A,$d.BOM_B)
  if($d.Lines -gt $changes.Count){ Write-Host '  警告: 变化行数多于修改项数，请检查是否有意外改动。' }
  if($d.CRLF_A -ne $d.CRLF_B -or $d.BOM_A -ne $d.BOM_B){ Write-Host '  警告: 换行或BOM发生变化，请检查文件。' }
  Write-Host ''
  Write-Host 'Steam 校验或游戏更新会覆盖 settings.ini，更新后需重新运行本工具。'
}

function Show-View([string]$text,[object]$hw,[array]$dups){
  Write-Host ''
  Write-Host ((Pad '级别' 16)+(Pad '参数' 40)+(Pad '当前' 12)+(Pad '参考' 12)+(Pad '来源' 10)+(Pad '影响' 18)+(Pad '置信' 8))
  Write-Host ('-'*116)
  foreach($p in $Params){
    $cur=Get-Val $text $p.Key
    $ls=Get-LocalSuggest $p $hw
    $curShow=if($null -eq $cur){ '(无此键)' }else{ $cur }
    $mark=''
    if($dups.Count -gt 0 -and ($dups.Key -contains $p.Key)){ $mark=' [重复键]' }
    Write-Host ((Pad $TierTag[$p.Tier] 16)+(Pad $p.Key 40)+(Pad $curShow 12)+(Pad $ls.V 12)+(Pad $p.Src 10)+(Pad $p.Impact 18)+(Pad $p.Conf 8)+$mark)
  }
  Write-Host ''
  Write-Host '? 查某项定义与影响；置信度: 确定 > 推定 > 推测 > 猜测。'
  Write-Host ''
  Write-Host ('保护项（本工具不读写）: '+($Protected -join ', '))
  Write-Host 'user_settings.config 不在本工具范围内。'
}

function Show-Detail([string]$text,[object]$hw){
  while($true){
    Write-Host ''
    Write-Host '输入参数名或编号查定义与影响（支持部分匹配），q 返回菜单'
    $s=Read-Host '查询'
    if($s -eq 'q' -or [string]::IsNullOrWhiteSpace($s)){ return }
    $s=$s.Trim()
    $found=@()
    $n=0
    if([int]::TryParse($s,[ref]$n) -and $n -ge 1 -and $n -le $Params.Count){ $found=@($Params[$n-1]) }
    else { $found=@($Params | Where-Object { $_.Key -like ('*'+$s+'*') }) }
    if($found.Count -eq 0){ Write-Host '没有匹配的参数'; continue }
    if($found.Count -gt 8){ Write-Host ("匹配 {0} 项，只显示前 8 项；换个关键词可缩小范围。" -f $found.Count); $found=@($found | Select-Object -First 8) }
    foreach($p in $found){
      $cur=Get-Val $text $p.Key
      if($null -eq $cur){ $cur='(无此键)' }
      $ls=Get-LocalSuggest $p $hw
      Write-Host ''
      Write-Host ('='*100)
      Write-Host ("{0}  {1}" -f $TierTag[$p.Tier],$p.Key)
      Write-Host ("  定义与影响 : {0}" -f $p.Note)
      Write-Host ("  影响       : {0}" -f $p.Impact)
      Write-Host ("  置信度     : {0}" -f $p.Conf)
      Write-Host ("  参考值来源 : {0}" -f $p.Src)
      Write-Host ("  当前 / 出厂 / 参考 : {0} / {1} / {2}" -f $cur,$p.Default,$ls.V)
      Write-Host ("  参考依据   : {0}" -f $ls.Why)
      Write-Host ("  适用条件   : {0}" -f $p.Cond)
    }
  }
}

function Save-Snapshot([string]$path,[string]$text,[object]$hw,[array]$dups,[array]$combos){
  $dir=[IO.Path]::GetDirectoryName($path)
  $f=[IO.Path]::Combine($dir,('HD2_snapshot_{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $hash=($sha.ComputeHash((Get-Raw $path)) | ForEach-Object { $_.ToString('x2') }) -join ''
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('Helldivers 2 settings.ini 只读快照')
  [void]$sb.AppendLine(('时间: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
  [void]$sb.AppendLine(('文件: {0}' -f $path))
  [void]$sb.AppendLine(('大小: {0} 字节' -f ([IO.FileInfo]::new($path)).Length))
  [void]$sb.AppendLine(('SHA256: {0}' -f $hash))
  [void]$sb.AppendLine(('CPU: {0} / 物理核 {1} / 逻辑核 {2}' -f $hw.CPUName,$hw.Physical,$hw.Logical))
  $ramTxt2=if($hw.RAM -gt 0){ "$($hw.RAM) MB" }else{ '未检测到' }
  [void]$sb.AppendLine(('内存: {0}' -f $ramTxt2))
  [void]$sb.AppendLine(('GPU: {0} / 厂商 {1} / 显存 {2} MB' -f $hw.GPU,$hw.Vendor,$hw.VRAM))
  [void]$sb.AppendLine(('系统盘: {0} / 笔记本: {1} / 双CCD型号匹配(推): {2}' -f $hw.Disk,$hw.Laptop,$hw.DualCCD))
  [void]$sb.AppendLine(('同名键: {0}' -f $(if($dups.Count -gt 0){($dups | ForEach-Object { "$($_.Key)x$($_.Count)" }) -join ', '}else{'无'})))
  [void]$sb.AppendLine(('组合冲突: {0}' -f $(if($combos.Count -gt 0){$combos -join '; '}else{'无'})))
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('级别 | 参数 | 当前 | 参考 | 来源 | 影响 | 置信度 | 适用条件 | 定义与影响')
  foreach($p in $Params){
    $cur=Get-Val $text $p.Key
    if($null -eq $cur){ $cur='(无此键)' }
    $ls=Get-LocalSuggest $p $hw
    [void]$sb.AppendLine(('{0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8}' -f $TierTag[$p.Tier],$p.Key,$cur,$ls.V,$p.Src,$p.Impact,$p.Conf,$p.Cond,$p.Note))
  }
  [void]$sb.AppendLine('')
  foreach($k in $Protected){ [void]$sb.AppendLine(('保护项 {0} = {1}' -f $k,(Get-Val $text $k))) }
  [IO.File]::WriteAllText($f,$sb.ToString(),(New-Object System.Text.UTF8Encoding($false)))
  Write-Host ("快照已导出: {0}" -f [IO.Path]::GetFileName($f))
}

function Export-Preset([string]$path,[string]$text){
  $dir=[IO.Path]::GetDirectoryName($path)
  $f=[IO.Path]::Combine($dir,('HD2_preset_{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
  $o=[ordered]@{}
  $o.Created=(Get-Date -Format 'o')
  $o.Tool='HD2_ini_tuner_advanced'
  $v=[ordered]@{}
  foreach($p in $Params){ $v[$p.Key]=Get-Val $text $p.Key }
  $o.Values=$v
  [IO.File]::WriteAllText($f,($o | ConvertTo-Json -Depth 5),(New-Object System.Text.UTF8Encoding($false)))
  Write-Host ("预设已导出: {0}" -f [IO.Path]::GetFileName($f))
}

function Import-Preset([string]$path,[string]$text,[object]$hw){
  $dir=[IO.Path]::GetDirectoryName($path)
  $files=@(Get-ChildItem -LiteralPath $dir -Filter 'HD2_preset_*.json' -File | Sort-Object LastWriteTime -Descending)
  if($files.Count -eq 0){ Write-Host '同目录下没有预设文件'; return $false }
  Write-Host '可用预设（最新在前）：'
  for($i=0;$i -lt [Math]::Min($files.Count,8);$i++){ Write-Host ("  [{0}] {1}" -f ($i+1),$files[$i].Name) }
  $s=Read-Host '输入编号，回车用第 1 个，q 取消'
  if($s -eq 'q'){ return $false }
  $n=1
  if(-not [string]::IsNullOrWhiteSpace($s)){ $tmp=0; if([int]::TryParse($s,[ref]$tmp) -and $tmp -ge 1 -and $tmp -le $files.Count){ $n=$tmp } }
  try { $j=Get-Content -Raw -LiteralPath $files[$n-1].FullName | ConvertFrom-Json } catch { Write-Host '预设解析失败'; return $false }
  $keys=@($Params | ForEach-Object { $_.Key })
  $unknown=@(); $badVal=@(); $absent=@()
  $changes=@()
  foreach($pr in $j.Values.PSObject.Properties){
    if($keys -notcontains $pr.Name){ $unknown+=$pr.Name; continue }
    $p=@($Params | Where-Object { $_.Key -eq $pr.Name })[0]
    $cur=Get-Val $text $pr.Name
    if($null -eq $cur){ $absent+=$pr.Name; continue }
    $v=[string]$pr.Value
    if($v -match '^(?i)(true|false)$'){ $v=$v.ToLower() }
    if(-not (Test-Val $v $p.Default)){ $badVal+=$pr.Name; continue }
    if($v -eq $cur){ continue }
    $changes+=[pscustomobject]@{Key=$pr.Name;From=$cur;To=$v;Tier=$p.Tier;Cond=$p.Cond}
  }
  if($unknown.Count -gt 0){ Write-Host ("预设里有未知参数，已跳过: {0}" -f ($unknown -join ', ')) }
  if($badVal.Count -gt 0){ Write-Host ("预设里有类型不符的值，已跳过: {0}" -f ($badVal -join ', ')) }
  if($absent.Count -gt 0){ Write-Host ("预设里对应键在本文件中不存在，已跳过: {0}" -f ($absent -join ', ')) }
  Write-Host ''
  Write-Host '预设导入会覆盖下列项。这是外部数值，不保证适合本机硬件：'
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad $c.From 14),$c.To) }
  if(-not (Confirm-Write $changes 'import')){ return $false }
  Apply-Changes $path $text $changes
  return $true
}

function Manage-Backups([string]$path){
  $dir=[IO.Path]::GetDirectoryName($path)
  while($true){
    $baks=@(Get-ChildItem -LiteralPath $dir -Filter 'settings.ini.bak-*' -File | Sort-Object LastWriteTime -Descending)
    Write-Host ''
    Write-Host ("备份共 {0} 个：" -f $baks.Count)
    for($i=0;$i -lt [Math]::Min($baks.Count,15);$i++){ Write-Host ("  [{0}] {1}  {2} 字节" -f ($i+1),$baks[$i].Name,$baks[$i].Length) }
    Write-Host 'd=删除指定编号  k=只保留最近N个  r=从某个备份还原  q=返回菜单'
    $s=Read-Host '选择'
    if($s -eq 'q'){ return }
    if($s -eq 'd'){
      $x=Read-Host '要删除的编号'
      $n=0
      if([int]::TryParse($x,[ref]$n) -and $n -ge 1 -and $n -le $baks.Count){
        $c=Read-Host ("确认删除 {0}? 输入 yes" -f $baks[$n-1].Name)
        if($c -eq 'yes'){ Remove-Item -LiteralPath $baks[$n-1].FullName -Force; Write-Host '已删除' }
      } else { Write-Host '编号无效' }
      continue
    }
    if($s -eq 'k'){
      $x=Read-Host '保留最近几个（其余删除）'
      $n=0
      if([int]::TryParse($x,[ref]$n) -and $n -ge 1 -and $baks.Count -gt $n){
        $c=Read-Host ("将删除 {0} 个旧备份，输入 yes 确认" -f ($baks.Count-$n))
        if($c -eq 'yes'){ for($i=$n;$i -lt $baks.Count;$i++){ Remove-Item -LiteralPath $baks[$i].FullName -Force }; Write-Host '已清理' }
      } else { Write-Host '数量无效或无需清理' }
      continue
    }
    if($s -eq 'r'){
      if($baks.Count -eq 0){ Write-Host '没有备份'; continue }
      $x=Read-Host '要还原的编号，回车用第 1 个'
      $n=1
      if(-not [string]::IsNullOrWhiteSpace($x)){ $tmp=0; if([int]::TryParse($x,[ref]$tmp) -and $tmp -ge 1 -and $tmp -le $baks.Count){ $n=$tmp } }
      $b=New-Backup $path
      Write-Host ("当前文件已备份为 {0}" -f [IO.Path]::GetFileName($b))
      [IO.File]::Copy($baks[$n-1].FullName,$path,$true)
      Write-Host '已还原。'
      return
    }
    Write-Host '无效选择'
  }
}

function Select-TierApply([string]$text,[object]$hw){
  Write-Host ''
  Write-Host '按分级批量套用参考值：'
  for($i=0;$i -lt $TierOrder.Count;$i++){
    $t=$TierOrder[$i]
    $n=@($Params | Where-Object { $_.Tier -eq $t }).Count
    Write-Host ("  [{0}] {1}  共 {2} 项" -f ($i+1),(Pad $TierTag[$t] 16),$n)
  }
  $s=Read-Host '输入编号，q 取消'
  if($s -eq 'q'){ return @() }
  $n=0
  if(-not [int]::TryParse($s,[ref]$n) -or $n -lt 1 -or $n -gt $TierOrder.Count){ Write-Host '编号无效'; return @() }
  $tier=$TierOrder[$n-1]
  $changes=@(); $absent=@()
  foreach($p in @($Params | Where-Object { $_.Tier -eq $tier })){
    $cur=Get-Val $text $p.Key
    if($null -eq $cur){ $absent+=$p.Key; continue }
    $ls=Get-LocalSuggest $p $hw
    if($ls.V -ne $cur){ $changes+=[pscustomobject]@{Key=$p.Key;From=$cur;To=$ls.V;Tier=$p.Tier;Cond=$p.Cond} }
  }
  if($absent.Count -gt 0){ Write-Host ("文件中不存在的键已跳过: {0}" -f ($absent -join ', ')) }
  return $changes
}

function Get-AutoChanges([string]$text,[object]$hw){
  $changes=@(); $excluded=@(); $absent=@()
  foreach($p in $Params){
    if($p.Tier -eq 'HWSPEC' -or $p.Tier -eq 'CAUTION'){ $excluded+=$p.Key; continue }
    $cur=Get-Val $text $p.Key
    if($null -eq $cur){ $absent+=$p.Key; continue }
    $ls=Get-LocalSuggest $p $hw
    if($ls.V -ne $cur){ $changes+=[pscustomobject]@{Key=$p.Key;From=$cur;To=$ls.V;Tier=$p.Tier;Cond=$p.Cond} }
  }
  Write-Host ("批量套用已排除 {0} 项 [按硬件]/[谨慎]，它们不进批量：" -f $excluded.Count)
  Write-Host ("  {0}" -f ($excluded -join ', '))
  if($absent.Count -gt 0){
    Write-Host ("文件中不存在的键 {0} 项，已跳过（旧版本可能没有对应配置段）：" -f $absent.Count)
    Write-Host ("  {0}" -f ($absent -join ', '))
  }
  return $changes
}

function Get-DryRun([string]$path,[string]$text,[array]$changes){
  Write-Host ''
  Write-Host '==== 干跑预览（不写入）===='
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad $c.From 14),$c.To) }
  $new=$text
  foreach($c in $changes){ $r=Set-Val $new $c.Key $c.To; $new=$r.Text }
  $rawA=Get-Raw $path
  $rawB=$Latin.GetBytes($new)
  $d=Get-ByteDiff $rawA $rawB
  Write-Host ("  改动范围: 变化 {0} 行，行号 {1}，长度 {2} -> {3}" -f $d.Lines,$d.LineNums,$d.LenA,$d.LenB)
  Write-Host ("  CRLF {0} -> {1}  BOM {2} -> {3}" -f $d.CRLF_A,$d.CRLF_B,$d.BOM_A,$d.BOM_B)
  $combos=Get-ComboWarnings $new
  foreach($w in $combos){ Write-Host ("  警告: {0}" -f $w) }
  Write-Host '文件未修改。'
}

# ===== 主流程 =====
$path=Find-Ini
if(-not $path){ Write-Host '已退出'; exit 0 }
$hw=Get-HW $path
Write-Host ''
Write-Host '==== 本机硬件检测 ===='
Write-Host ("  CPU: {0}" -f $hw.CPUName)
$ramTxt=if($hw.RAM -gt 0){ "$($hw.RAM) MB" }else{ '未检测到（相关项按保守默认处理）' }
Write-Host ("  核心: 物理 {0} / 逻辑 {1}   物理内存 {2}" -f $hw.Physical,$hw.Logical,$ramTxt)
if($hw.VRAM -gt 0){ Write-Host ("  GPU: {0} / 厂商 {1} / 显存约 {2} MB ({3} GB)" -f $hw.GPU,$hw.Vendor,$hw.VRAM,[math]::Round($hw.VRAM/1024,1)) }
else { Write-Host ("  GPU: {0} / 显存未检测到（相关项保持默认）" -f $hw.GPU) }
Write-Host ("  系统盘: {0}   笔记本: {1}" -f $hw.Disk,$hw.Laptop)
Write-Host ("  双CCD型号匹配: {0}  【推】仅按名称匹配，不作准，只影响提示文字" -f $hw.DualCCD)
Write-Host '  注：参考值标「按硬件」的由本机检测结果推算；「通用」与硬件无关；「按目标」取决于要画质还是帧数，工具不替你定。'
Write-Host ''
Write-Host ("文件: {0}" -f $path)
Write-Host ("大小: {0} 字节" -f ([IO.FileInfo]::new($path)).Length)
$text0=Get-IniText $path
if($text0 -notmatch 'stingray_version|project_name'){
  Write-Host '警告: 该文件里没有 stingray_version 或 project_name，可能不是 HD2 的 settings.ini'
  $go=Read-Host '仍要继续? y/N'
  if($go -ne 'y'){ exit 0 }
}
Write-Host '按字节读写，不改编码、不改换行、不动行尾注释；写入前自动备份。'

while($true){
  $text=Get-IniText $path
  $dups=Get-DuplicateKeys $text
  $combos=Get-ComboWarnings $text
  Show-Warnings $dups $combos
  Write-Host ''
  Write-Host '==== 菜单 ===='
  Write-Host '  回车  逐项修改          a  批量套用参考值（排除高风险）'
  Write-Host '  t     按分级批量         d  干跑预览（不写入）'
  Write-Host '  v     只看当前值         ?  查某项定义与影响'
  Write-Host '  s     导出只读快照       e  导出预设           i  导入预设'
  Write-Host '  b     备份管理（列/删/清理/还原）          q  退出'
  $mode=Read-Host '选择'
  if($mode -eq 'q'){ break }
  if($mode -eq '?'){ Show-Detail $text $hw; continue }
  if($mode -eq ''){
    $changes=@()
    Write-Host ''
    Write-Host '逐项选择。回车跳过，y 用参考值，r 用出厂值，直接输入数值自定义，q 结束选择。'
    for($i=0;$i -lt $Params.Count;$i++){
      $p=$Params[$i]
      $cur=Get-Val $text $p.Key
      if($null -eq $cur){
        Write-Host ''
        Write-Host ("[{0,2}/{1,2}] {2} {3}" -f ($i+1),$Params.Count,$TierTag[$p.Tier],$p.Key)
        Write-Host '        文件中不存在该键（旧版本可能没有对应配置段），已跳过。'
        continue
      }
      $ls=Get-LocalSuggest $p $hw
      Write-Host ''
      Write-Host ("[{0,2}/{1,2}] {2} {3}" -f ($i+1),$Params.Count,$TierTag[$p.Tier],$p.Key)
      Write-Host ("        当前 {0}   出厂 {1}   参考 {2}（{3}）   {4} / {5}" -f $cur,$p.Default,$ls.V,$p.Src,$p.Impact,$p.Conf)
      Write-Host ("        定义: {0}" -f $p.Note)
      Write-Host ("        参考依据: {0}" -f $ls.Why)
      Write-Host ("        适用条件: {0}" -f $p.Cond)
      if($p.Tier -eq 'CAUTION' -or $p.Tier -eq 'HWSPEC'){ Write-Host '        警告: 此项按硬件/谨慎级别，照抄可能翻车，确认条件后再改。' }
      $in=Read-Host '        选择 [回车跳过 / y 参考 / r 出厂 / 自定义 / q 结束]'
      if($in -eq 'q'){ break }
      if([string]::IsNullOrWhiteSpace($in)){ continue }
      $v=$in
      if($in -eq 'y'){ $v=$ls.V }
      elseif($in -eq 'r'){ $v=$p.Default }
      if(-not (Test-Val $v $p.Default)){
        Write-Host ("        输入 「{0}」 与该键类型（{1}）不符，已跳过。出厂值格式：{2}" -f $v,(Get-ValType $p.Default),$p.Default)
        continue
      }
      if($v -eq $cur){ continue }
      $changes+=[pscustomobject]@{Key=$p.Key;From=$cur;To=$v;Tier=$p.Tier;Cond=$p.Cond}
    }
    if(Confirm-Write $changes 'manual'){ Apply-Changes $path $text $changes; break }
    continue
  }
  if($mode -eq 'a'){
    $ch=Get-AutoChanges $text $hw
    if(Confirm-Write $ch 'auto'){ Apply-Changes $path $text $ch; break }
    continue
  }
  if($mode -eq 't'){
    $ch=Select-TierApply $text $hw
    if(Confirm-Write $ch 'tier'){ Apply-Changes $path $text $ch; break }
    continue
  }
  if($mode -eq 'd'){
    $ch=Get-AutoChanges $text $hw
    Get-DryRun $path $text $ch
    continue
  }
  if($mode -eq 'v'){ Show-View $text $hw $dups; continue }
  if($mode -eq 's'){ Save-Snapshot $path $text $hw $dups $combos; continue }
  if($mode -eq 'e'){ Export-Preset $path $text; continue }
  if($mode -eq 'i'){ if(Import-Preset $path $text $hw){ break }; continue }
  if($mode -eq 'b'){ Manage-Backups $path; continue }
  Write-Host '无效选择'
}
Write-Host ''
Write-Host '本工具不碰 user_settings.config，也不碰 dearimgui_enabled / crash_dump / floating_point_exceptions。'
Write-Host ''
