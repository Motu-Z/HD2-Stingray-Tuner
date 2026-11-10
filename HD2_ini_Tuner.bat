@echo off
chcp 936 >nul 2>&1
title Helldivers 2 settings.ini Tuner
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
# Tier: SAFE=机制  TRADEOFF=取舍  HWSPEC=硬件  CAUTION=风险
# Src : 引擎=与硬件无关的引擎层值 / 配置=据硬件性能的粗略估算 / 画面=对游戏画面的性能要求
# Conf: 确定=公开文档或可确证机制 / 推定=引擎模型推断 / 推测=按命名与方向推断 / 猜测=判定逻辑未知
# Suggest 为数据表参考值；画面项与置信为推测/猜测的项不显示统一参考值，参考列记为 -。
# 定义写在 Note，只在逐项修改或查详情时展开。
$Params=@(
 [pscustomobject]@{Key='num_reserved_threads';Default='2';Suggest='18';Tier='HWSPEC';Rule='threads';Src='配置';Impact='CPU·并行';Conf='推定';Cond='已限制游戏可用逻辑核集合时才需要改';Note='线程池保留线程数。引擎作业线程数 = 逻辑处理器总数 − 本值；32 逻辑核下，保留 2 对应 30 条作业线程，保留 18 对应 14 条。影响 CPU 并行吞吐与 fork-join 尾延迟。若已通过 CPU Sets、BIOS 或处理器亲和性限制可用逻辑核集合，须按 reserved = 逻辑核总数 − 目标线程数 重新计算；该关系与 CPU 厂商及核心拓扑无关。'}
 [pscustomobject]@{Key='memory_budget_mb';Default='1536';Suggest='3072';Tier='HWSPEC';Rule='membudget';Src='配置';Impact='显存·驻留';Conf='推定';Cond='显存充足且游戏所在磁盘为SSD时';Note='流送纹理常驻 Mip 数据量（MB）。调高可提升纹理清晰度并减少重复载入，代价是显存驻留增加；超出物理显存将引发频繁驱逐并导致帧率显著下降。'}
 [pscustomobject]@{Key='texture_heap_usage_limit';Default='5376';Suggest='6144';Tier='HWSPEC';Rule='heap';Src='配置';Impact='显存·上限';Conf='推定';Cond='必须匹配显存';Note='D3D12 纹理堆驻留上限（MB）。决定纹理可申请的显存堆大小；超过物理显存会退化至共享内存，导致帧率显著下降。'}
 [pscustomobject]@{Key='hdr_enabled';Default='false';Suggest='false';Tier='HWSPEC';Rule='hdr';Src='配置';Impact='画面·色彩';Conf='确定';Cond='仅显示器支持HDR且已在Windows开启HDR时';Note='HDR 输出开关。需显示器与 Windows HDR 同时支持；配置错误会导致色彩发灰或亮度异常。本工具不自动修改该项。'}
 [pscustomobject]@{Key='prefer_hdr';Default='false';Suggest='false';Tier='HWSPEC';Rule='hdr';Src='配置';Impact='画面·色彩';Conf='确定';Cond='同上';Note='HDR 偏好开关。必须与 hdr_enabled 保持一致，否则可能导致 HDR 判定混乱。'}
 [pscustomobject]@{Key='minimum_unload_delay';Default='2';Suggest='30';Tier='SAFE';Rule='delay';Src='配置';Impact='显存·驻留';Conf='推测';Cond='通用';Note='纹理最短驻留时间，单位推断为秒。延长可抑制反复驱逐与重载，减少帧时间抖动，代价是显存常驻量上升。'}
 [pscustomobject]@{Key='minimum_shrink_delay';Default='30';Suggest='90';Tier='SAFE';Rule='delay';Src='配置';Impact='显存·抖动';Conf='推测';Cond='通用';Note='流送池收缩前的等待时长。延长可减少池重分配与帧时间抖动，代价是显存回收变慢。'}
 [pscustomobject]@{Key='max_frame_copy_bytes';Default='67108864';Suggest='100663296';Tier='SAFE';Rule='copyband';Src='配置';Impact='显存·拷贝';Conf='推测';Cond='通用';Note='单帧 GPU 内拷贝上限（字节），占用显存带宽。通常冗余度较高；放宽对帧率影响有限，小显存设备可能放大单帧压力。'}
 [pscustomobject]@{Key='max_frame_upload_bytes';Default='16777216';Suggest='16777216';Tier='SAFE';Rule='keep';Src='引擎';Impact='帧时间·尖峰';Conf='推定';Cond='无改动依据';Note='单帧 CPU→GPU 上传上限，默认 16 MB，走 PCIe 带宽。作为抑制单帧 PCIe 尖峰的节流阈值，放宽可能放大帧时间波动。'}
 [pscustomobject]@{Key='pipeline_cache_prune_size';Default='256';Suggest='512';Tier='SAFE';Rule='keep';Src='引擎';Impact='帧时间·编译卡顿';Conf='推测';Cond='通用';Note='管线缓存裁剪阈值。调大可减少着色器重编译卡顿，代价是缓存文件增大、磁盘占用上升。'}
 [pscustomobject]@{Key='pso_cache_prune_size';Default='512';Suggest='1024';Tier='SAFE';Rule='keep';Src='引擎';Impact='帧时间·编译卡顿';Conf='推测';Cond='通用';Note='PSO blob 缓存裁剪阈值，机制同上。'}
 [pscustomobject]@{Key='anti_lag';Default='true';Suggest='false';Tier='SAFE';Rule='keep';Src='画面';Impact='延迟·帧节奏';Conf='推定';Cond='取决于驱动侧抗延迟功能的启用状态';Note='引擎侧帧节奏控制开关。与驱动侧抗延迟机制作用于同一提交环节；两者同时启用时，帧提交时机将被两套机制共同干预。'}
 [pscustomobject]@{Key='memory_size';Default='26214400';Suggest='78643200';Tier='SAFE';Rule='wwisepool';Src='配置';Impact='音频·缓冲';Conf='确定';Cond='物理内存16GB以上且游戏所在磁盘为SSD';Note='Wwise 流式 I/O 缓冲池字节数（uIOMemorySize）。缓冲块数 = 本值 / granularity；默认 25 MB / 128 KB = 200 块。影响音频预读能力，不直接改变帧率。'}
 [pscustomobject]@{Key='max_concurrent_io';Default='200';Suggest='200';Tier='SAFE';Rule='ioconcurrent';Src='配置';Impact='音频·IO';Conf='确定';Cond='无改动依据';Note='Wwise 并发 I/O 请求数（uMaxConcurrentIO）。SDK 默认 8，默认 200 与默认缓冲块数配套；降低并发未见显著收益。'}
 [pscustomobject]@{Key='verbose';Default='true';Suggest='false';Tier='SAFE';Rule='keep';Src='引擎';Impact='磁盘·写日志';Conf='推定';Cond='通用';Note='EOS 详细日志开关。开启后持续写入日志，产生额外磁盘 I/O；关闭对帧率影响有限，主要收益是降低日志量。'}
 [pscustomobject]@{Key='use_syncapi';Default='true';Suggest='true';Tier='SAFE';Rule='keep';Src='引擎';Impact='CPU·空闲';Conf='推定';Cond='无改动依据';Note='线程池空闲时采用阻塞等待而非自旋。降低空闲 CPU 占用，高负载下无差异。'}
 [pscustomobject]@{Key='command_queue_size';Default='524288';Suggest='524288';Tier='SAFE';Rule='keep';Src='引擎';Impact='音频·命令';Conf='确定';Cond='无改动依据';Note='Wwise 音频命令队列字节数（uCommandQueueSize）。默认 512 KB，为 SDK 默认值的 2 倍；队列满时会丢弃音频命令，默认容量已有余量。'}
 [pscustomobject]@{Key='pool_size';Default='33554432';Suggest='33554432';Tier='SAFE';Rule='keep';Src='引擎';Impact='内存·音频池';Conf='确定';Cond='无改动依据';Note='Wwise 声音引擎默认内存池（uDefaultPoolSize）。默认 32 MB，为 SDK 默认值的 2 倍；影响可同时驻留的声音对象数量。'}
 [pscustomobject]@{Key='num_refills_in_voice';Default='4';Suggest='4';Tier='SAFE';Rule='keep';Src='引擎';Impact='音频·缓冲';Conf='确定';Cond='无改动依据';Note='流式声音缓冲补充次数（uNumRefillsInVoice），SDK 默认 4。影响流式音频的缓冲深度与抗抖动能力。'}
 [pscustomobject]@{Key='memory_alignment';Default='64';Suggest='64';Tier='SAFE';Rule='keep';Src='引擎';Impact='音频·IO对齐';Conf='确定';Cond='无改动依据';Note='Wwise I/O 内存对齐字节数（uIOMemoryAlignment）。默认 64，SDK 默认 4。修改将影响底层 I/O 请求的对齐方式。'}
 [pscustomobject]@{Key='scratch_space';Default='128';Suggest='128';Tier='SAFE';Rule='keep';Src='引擎';Impact='显存·上传缓冲';Conf='推定';Cond='无改动依据';Note='D3D12 临时与上传缓冲区（MB）。默认 128 MB，冗余度充足；设置过小可能导致上传等待。'}
 [pscustomobject]@{Key='atmospheric_scattering_ambience_samples';Default='128';Suggest='64';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='GPU·画质/帧率';Conf='确定';Cond='GPU瓶颈且开放天空场景时';Note='环境散射积分采样数（等于 GPU 着色器循环次数）。减半可近似线性降低该 pass 的 GPU 开销并提升帧率；画面可能出现色带或噪点。'}
 [pscustomobject]@{Key='sun_step_length_multiplier';Default='0.17';Suggest='0.4';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='GPU·画质/帧率';Conf='确定';Cond='GPU瓶颈且开放天空场景时';Note='太阳方向 ray-march 步长缩放系数（步数与系数成反比）。默认 0.17 调整为 0.4 约使步数降至 42.5%，可降低 GPU 开销；步长过大会产生条带伪影。'}
 [pscustomobject]@{Key='cloud_step_length';Default='8';Suggest='8';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='GPU·画质/帧率';Conf='推定';Cond='体积云 GPU 成本占比高时';Note='体积云光线步进步长。调大可减少步数、降低 GPU 开销；过大将产生层状伪影。本工具不自动修改该项，仅提供调整方向。'}
 [pscustomobject]@{Key='realtime_cubemaps_nr_regular_samples';Default='32';Suggest='32';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='GPU·画质/帧率';Conf='推定';Cond='实时反射 GPU 成本占比高时';Note='实时反射 cubemap 常规采样数。减小可降低 GPU 开销，反射画面将变模糊；同族的 far、space 与 downsample 另有独立采样组。'}
 [pscustomobject]@{Key='fullscreen';Default='false';Suggest='false';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='延迟·合成';Conf='确定';Cond='与borderless_fullscreen必须一真一假';Note='独占全屏开关。绕过 DWM 合成，降低输入延迟并使驱动侧低延迟特性完整生效；代价是 Alt-Tab 切换变慢、部分叠加层（overlay）显示异常。必须与 borderless_fullscreen 一真一假。'}
 [pscustomobject]@{Key='borderless_fullscreen';Default='true';Suggest='true';Tier='TRADEOFF';Rule='keep';Src='画面';Impact='延迟·合成';Conf='确定';Cond='与fullscreen必须一真一假';Note='无边框全屏开关。经 DWM 合成，增加额外一帧延迟。必须与 fullscreen 一真一假，否则组合非法；修改 fullscreen 时本项需同步取反。'}
 [pscustomobject]@{Key='max_frame_updates';Default='32';Suggest='64';Tier='CAUTION';Rule='frameupdates';Src='引擎';Impact='帧时间·尖峰';Conf='推定';Cond='取决于纹理加载速度与帧时间余量';Note='单帧允许处理的流送更新条数。调高会放大渲染线程的偶发尖峰；该取舍取决于纹理加载速度与帧时间余量。'}
 [pscustomobject]@{Key='granularity';Default='131072';Suggest='131072';Tier='CAUTION';Rule='keep';Src='引擎';Impact='音频·IO块';Conf='确定';Cond='改动会破坏配套项';Note='Wwise 单次 I/O 请求字节数（uGranularity）。默认 128 KB，SDK 默认 16 KB。修改将破坏与 memory_size、max_concurrent_io 的缓冲块数配套关系。'}
 [pscustomobject]@{Key='target_buffering_length';Default='720';Suggest='720';Tier='CAUTION';Rule='keep';Src='引擎';Impact='音频·预读';Conf='确定';Cond='改动会破坏配套项';Note='Wwise 目标预读缓冲时长（fTargetAutoStmBufferLength），单位毫秒。调大须同步增加 memory_size，否则目标值不可达。'}
 [pscustomobject]@{Key='use_blocking_io';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='CPU·音频线程';Conf='确定';Cond='无改动依据';Note='Wwise I/O 调度模式；false 为 deferred（延迟提交）。设为 true 将退化为阻塞式调度并额外创建线程，增加 CPU 占用。'}
 [pscustomobject]@{Key='num_samples_per_frame';Default='1024';Suggest='1024';Tier='CAUTION';Rule='keep';Src='引擎';Impact='音频·延迟';Conf='确定';Cond='仅在音频畸变且排除链路问题后';Note='音频渲染每块样本数（uNumSamplesPerFrame）。1024 样本在 48 kHz 下约 21.3 ms；改为 2048 将增加约 21 ms 音频延迟，仅扩大缓冲而不消除链路瓶颈。'}
 [pscustomobject]@{Key='max_cache_ratio';Default='1';Suggest='1';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='Wwise 缓存占比上限（fMaxCacheRatio）。判定逻辑未见公开说明，改动后果未知。'}
 [pscustomobject]@{Key='reflex_mode';Default='2';Suggest='0';Tier='CAUTION';Rule='reflex';Src='配置';Impact='延迟·CPU提交·帧时间';Conf='确定';Cond='仅 NVIDIA 显卡与驱动侧功能支持时生效';Note='NVIDIA Reflex 模式；0 = 关闭，2 = On + Boost。启用时限制 CPU 提前提交的帧数，改变帧提交节奏，作用于 CPU 侧提交时机，不直接改变渲染工作量；可观测指标为平均帧率与帧时间分布。'}
 [pscustomobject]@{Key='vsync';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='延迟·同步';Conf='确定';Cond='高刷屏且使用 VRR 时';Note='垂直同步开关。无边框模式下关闭 Vsync 无法获得低延迟，仍受 DWM 刷新率同步限制；VRR 配合帧率上限是另一种同步方式。'}
 [pscustomobject]@{Key='adapter_index';Default='0';Suggest='0';Tier='CAUTION';Rule='adapter';Src='配置';Impact='GPU·适配器';Conf='确定';Cond='多 GPU 机器的该值取决于 D3D 枚举顺序';Note='D3D 适配器索引。存在多个显示适配器时（核显加独显、多张独显、不同厂商组合），索引 0 未必指向实际渲染所用的 GPU；该值指向其他设备时，整套调优将作用于错误的设备。'}
 [pscustomobject]@{Key='d3d_debug';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='帧率·大幅下降';Conf='确定';Cond='开启会大幅降低帧率';Note='D3D 调试层开关。开启会显著增加渲染开销并大幅降低帧率。'}
 [pscustomobject]@{Key='drs_minimum_scale_factor';Default='0.5';Suggest='0.5';Tier='CAUTION';Rule='keep';Src='引擎';Impact='画质/帧率';Conf='推定';Cond='实际开关在user_settings.config';Note='动态分辨率下限比例。实际开关由 user_settings.config 控制，settings.ini 中的对应段可能被用户配置覆盖，修改本项未必生效。'}
 [pscustomobject]@{Key='max_num_jobs';Default='8192';Suggest='8192';Tier='CAUTION';Rule='keep';Src='引擎';Impact='CPU·队列';Conf='推定';Cond='无改动依据';Note='作业队列容量上限（非并发度）。默认值 8192 在 14 条作业线程下不会成为瓶颈。'}
 [pscustomobject]@{Key='metrics_batch_timer';Default='30';Suggest='30';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='猜测';Cond='未验证开销';Note='遥测批量上报周期，单位推测为秒。无证据表明其造成周期性帧时间尖峰。'}
 [pscustomobject]@{Key='minimum_unseen_delay';Default='60';Suggest='60';Tier='CAUTION';Rule='keep';Src='引擎';Impact='显存·卸载';Conf='猜测';Cond='判定逻辑未知';Note='纹理未被渲染多久后进入卸载候选。判定逻辑未公开，改动后果未知。'}
 [pscustomobject]@{Key='inv_texel_density';Default='4';Suggest='4';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='纹素密度相关项。其语义与单位未见可靠公开说明，改动后果未知。'}
 [pscustomobject]@{Key='max_mip';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='流送 Mip 上限。取值语义未见可靠公开说明，改动后果未知。'}
 [pscustomobject]@{Key='memory_threshold_fast_shrink';Default='33554432';Suggest='33554432';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='推测';Cond='判定逻辑未知';Note='触发流送池快速收缩的内存阈值（默认 32 MB）。可由命名推断其作用方向，但具体判定逻辑未公开。'}
 [pscustomobject]@{Key='initialize_at_max';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='显存·首帧';Conf='推测';Cond='无改动依据';Note='是否按最高 Mip 初始化纹理。改动会改变首次加载行为与首帧显存占用。'}
 [pscustomobject]@{Key='streaming_update_quick_drops';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='未知';Conf='猜测';Cond='判定逻辑未知';Note='流送更新快速丢弃开关。判定逻辑未公开，改动后果未知。'}
 [pscustomobject]@{Key='drop_dynamic_textures_on_renderer_reload';Default='false';Suggest='false';Tier='CAUTION';Rule='keep';Src='引擎';Impact='画质·重载';Conf='推测';Cond='无改动依据';Note='渲染器重载时是否丢弃动态纹理。改动可能导致重载后纹理缺失。'}
 [pscustomobject]@{Key='streaming_texture_pool_size';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='引擎';Impact='显存·池';Conf='确定';Cond='无改动依据';Note='Stingray 官方段：可流送纹理共享内存上限（MB），官方默认 256。置 0 表示由 texture_streaming 扩展段接管；填入非 0 值会与扩展段冲突。'}
 [pscustomobject]@{Key='streaming_buffer_size';Default='0';Suggest='0';Tier='CAUTION';Rule='keep';Src='引擎';Impact='内存·载入';Conf='确定';Cond='无改动依据';Note='Stingray 官方段：从磁盘载入新纹理的缓冲区大小（MB），官方默认 24。置 0 表示由扩展段接管。'}
 [pscustomobject]@{Key='max_num_jobs_data_dir';Default='32768';Suggest='32768';Tier='CAUTION';Rule='keep';Src='引擎';Impact='CPU·加载队列';Conf='推定';Cond='无改动依据';Note='数据目录加载阶段作业队列容量上限（非并发度）。'}
)
# ===== 配置区结束 =====


$TierTag=@{SAFE='[机制]';TRADEOFF='[取舍]';HWSPEC='[硬件]';CAUTION='[风险]'}
$TierOrder=@('SAFE','TRADEOFF','HWSPEC','CAUTION')
$Protected=@('dearimgui_enabled','crash_dump','floating_point_exceptions')

function Read-Key([string]$prompt){
  $s=Read-Host $prompt
  if($null -eq $s){ return '' }
  $sb=New-Object System.Text.StringBuilder
  foreach($ch in $s.ToCharArray()){
    $c=[int]$ch
    if($c -ge 0xFF01 -and $c -le 0xFF5E){ [void]$sb.Append([char]($c-0xFEE0)) }
    elseif($c -eq 0x3000){ [void]$sb.Append(' ') }
    else { [void]$sb.Append($ch) }
  }
  return $sb.ToString()
}

function Pad([string]$s,[int]$w){
  if($null -eq $s){ $s='' }
  $cw=0
  foreach($ch in $s.ToCharArray()){
    $c=[int]$ch
    if($c -eq 183 -or $c -eq 8593 -or $c -eq 8595){
      $cw+=1
    }
    elseif($c -gt 127){
      $cw+=2
    }
    else{
      $cw+=1
    }
  }
  if($cw -ge $w){ return $s }
  return $s + (' '*($w-$cw))
}

# 屏幕显示专用：ini 里的全精度浮点规整成等价短写法；读写始终保留原值
function Fmt-Val([string]$s){
  if($null -eq $s){ return $s }
  if($s -match '^-?\d+\.\d{8,}$'){
    try { return ([double]::Parse($s,[Globalization.CultureInfo]::InvariantCulture)).ToString('0.##########',[Globalization.CultureInfo]::InvariantCulture) } catch {}
  }
  return $s
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

# 按默认值推断该键类型，用于拒绝非法值写入
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
    $w+=("fullscreen 与 borderless_fullscreen 同为 {0}，组合非法。两者必须互斥。" -f $f)
  }
  $h=Get-Val $t 'hdr_enabled'; $ph=Get-Val $t 'prefer_hdr'
  if($h -and $ph -and ($h -ne $ph)){ $w+='hdr_enabled 与 prefer_hdr 取值不一致，将导致 HDR 判定冲突。' }
  return $w
}

function Get-ByteDiff([byte[]]$a,[byte[]]$b){
  # 按行比对，行数反映准确的改动范围
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

function Get-SteamLibs {
  $steamRoots = @()
  $cands = @()
  try { $v=(Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath;              if($v){ $cands += $v } } catch {}
  try { $v=(Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction Stop).InstallPath; if($v){ $cands += $v } } catch {}
  try { $v=(Get-ItemProperty 'HKLM:\SOFTWARE\Valve\Steam' -ErrorAction Stop).InstallPath;            if($v){ $cands += $v } } catch {}
  $steamRoots = @($cands | ForEach-Object { $_.Trim().Replace('/','\') } | Where-Object { $_ -and [IO.Directory]::Exists($_) } | Select-Object -Unique)
  $roots = @()
  foreach($sr in $steamRoots){
    if([IO.Directory]::Exists([IO.Path]::Combine($sr,'steamapps'))){ $roots += $sr }
  }
  foreach($sr in $steamRoots){
    $vdf = [IO.Path]::Combine($sr,'steamapps','libraryfolders.vdf')
    if(-not [IO.File]::Exists($vdf)){ continue }
    try {
      $txt = [IO.File]::ReadAllText($vdf,[Text.Encoding]::UTF8)
      foreach($m in [regex]::Matches($txt,'"path"\s*"([^"]+)"')){
        $p=$m.Groups[1].Value.Replace('\\','\')
        if([IO.Directory]::Exists($p)){ $roots += $p }
      }
      foreach($m in [regex]::Matches($txt,'"(\d+)"\s*"([^"]+)"')){
        $p=$m.Groups[2].Value.Replace('\\','\')
        if([IO.Directory]::Exists($p)){ $roots += $p }
      }
    } catch {}
  }
  return @($roots | Select-Object -Unique)
}

function Find-Ini(){
  $a=$env:HD2_ARG
  if($a){
    $a=$a.Trim().Trim('"')
    if([IO.File]::Exists($a)){ return $a }
    Write-Host ("命令行参数指定的文件不存在，继续自动搜索: {0}" -f $a)
  }

  $c=@()
  foreach($lib in (Get-SteamLibs)){
    $c += [IO.Path]::Combine($lib,'steamapps\common\Helldivers 2\data\settings.ini')
    $acf = [IO.Path]::Combine($lib,'steamapps\appmanifest_553850.acf')
    if([IO.File]::Exists($acf)){
      try {
        $at=[IO.File]::ReadAllText($acf,[Text.Encoding]::UTF8)
        $mm=[regex]::Match($at,'"installdir"\s*"([^"]+)"')
        if($mm.Success){
          $idir=$mm.Groups[1].Value.Replace('\\','\')
          $c += [IO.Path]::Combine($lib,'steamapps\common',$idir,'data\settings.ini')
        }
      } catch {}
    }
  }
  foreach($d in [IO.DriveInfo]::GetDrives()){
    if($d.DriveType -ne 'Fixed'){ continue }
    $r=$d.RootDirectory.FullName
    $c += [IO.Path]::Combine($r,'Steam\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'SteamLibrary\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'Program Files (x86)\Steam\steamapps\common\Helldivers 2\data\settings.ini')
    $c += [IO.Path]::Combine($r,'Games\Steam\steamapps\common\Helldivers 2\data\settings.ini')
  }

  $hitRaw=@($c | Where-Object { [IO.File]::Exists($_) })
  $hit=@()
  $seen=@{}
  foreach($p in $hitRaw){
    $k=$p.ToLowerInvariant()
    if(-not $seen.ContainsKey($k)){
      $seen[$k]=$true
      $hit+=$p
    }
  }
  if($hit.Count -eq 1){ return $hit[0] }
  if($hit.Count -gt 1){
    Write-Host '找到多个 settings.ini：'
    for($i=0;$i -lt $hit.Count;$i++){ Write-Host ("  [{0}] {1}" -f ($i+1),$hit[$i]) }
    $s=Read-Key '输入编号，回车用第 1 个'
    if([string]::IsNullOrWhiteSpace($s)){ return $hit[0] }
    $n=0; if([int]::TryParse($s,[ref]$n) -and $n -ge 1 -and $n -le $hit.Count){ return $hit[$n-1] }
    Write-Host '编号无效，使用第 1 个'; return $hit[0]
  }
  Write-Host '未自动找到 settings.ini。'
  $u=Read-Host '将文件拖入窗口后回车，或粘贴完整路径'
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
  return [pscustomobject]@{Logical=$logical;Physical=$physical;RAM=$ram;VRAM=$vram;GPU=$gpu;Vendor=$vendor;Disk=$disk;CPUName=$cpuName}
}

function Get-LocalSuggest([object]$p,[object]$hw){
  if($p.Src -eq '画面'){ return [pscustomobject]@{V='-';Why='取值取决于画质/帧率取向，工具不提供统一参考值。'} }
  if($p.Conf -eq '推测' -or $p.Conf -eq '猜测'){ return [pscustomobject]@{V='-';Why='该项依据不足，不提供统一参考值。'} }
  switch($p.Rule){
    'threads' {
      return [pscustomobject]@{V='-';Why=("检测到 {0} 逻辑核。仅在限制了可用逻辑核集合时（如 CPU Sets、BIOS 或亲和性），才需按 reserved = 逻辑核总数 - 目标线程数 计算。" -f $hw.Logical)}
    }
    'membudget' {
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=("游戏所在磁盘为 HDD，IO 抖动风险高，取默认值 {0}MB。" -f $p.Default)} }
      if($hw.VRAM -ge 12000){ return [pscustomobject]@{V='3072';Why=("显存约 {0}MB，取 3072MB 可平衡驻留与余量。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 8000){ return [pscustomobject]@{V='2048';Why=("显存约 {0}MB，取 2048MB 留出余量。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 6000){ return [pscustomobject]@{V='1792';Why=("显存约 {0}MB，取 1792MB。" -f $hw.VRAM)} }
      else { return [pscustomobject]@{V=$p.Default;Why=("显存 {0}MB 或未检测到，取默认值 {1}。" -f $hw.VRAM,$p.Default)} }
    }
    'heap' {
      if($hw.VRAM -ge 16000){ return [pscustomobject]@{V='8192';Why=("显存约 {0}MB，堆上限可取 8192MB。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 12000){ return [pscustomobject]@{V='6144';Why=("显存约 {0}MB，取 6144MB 保留余量。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 8000){ return [pscustomobject]@{V='4096';Why=("显存约 {0}MB，取 4096MB。" -f $hw.VRAM)} }
      elseif($hw.VRAM -ge 6000){ return [pscustomobject]@{V='3072';Why=("显存约 {0}MB，取 3072MB。" -f $hw.VRAM)} }
      else { return [pscustomobject]@{V=$p.Default;Why=("显存 {0}MB 或未检测到，取默认值 {1}。" -f $hw.VRAM,$p.Default)} }
    }
    'wwisepool' {
      if($hw.RAM -le 0){ return [pscustomobject]@{V=$p.Default;Why=('物理内存未检测到，取默认 25MB。')} }
      if($hw.RAM -lt 16000){ return [pscustomobject]@{V=$p.Default;Why=("物理内存约 {0}MB 偏小，取默认 25MB。" -f $hw.RAM)} }
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=('游戏所在磁盘为 HDD，并发读争抢风险高，取默认 25MB。')} }
      if($hw.Disk -eq '未知'){ return [pscustomobject]@{V=$p.Default;Why=('游戏所在磁盘类型未知，无法确认 SSD 性能，取默认 25MB。')} }
      return [pscustomobject]@{V='78643200';Why=('内存充足且为 SSD，取 75MB（600块@128KB）以确保 720ms 预读目标可达。')}
    }
    'ioconcurrent' {
      if($hw.Disk -eq 'HDD'){ return [pscustomobject]@{V=$p.Default;Why=('HDD 上高并发可能加重争抢，取默认值。')} }
      return [pscustomobject]@{V=$p.Default;Why=('与缓冲块数配套，取默认值。')}
    }
    'reflex' {
      if($hw.Vendor -ne 'NVIDIA'){ return [pscustomobject]@{V=$p.Suggest;Why=("GPU 厂商 {0}；该项依赖 NVIDIA 驱动侧支持。" -f $hw.Vendor)} }
      return [pscustomobject]@{V=$p.Suggest;Why=('0=关闭，2=On+Boost。')}
    }
    'hdr' {
      return [pscustomobject]@{V=$p.Default;Why=('取决于显示器 HDR 支持与 Windows HDR 开关，不自动开启。')}
    }
    'frameupdates' {
      return [pscustomobject]@{V='32';Why='取 32。翻倍将放大渲染线程尖峰。'}
    }
    'delay' {
      if($hw.VRAM -le 0){ return [pscustomobject]@{V=$p.Default;Why='显存未检测到，取默认值。'} }
      if($hw.VRAM -ge 10000){ return [pscustomobject]@{V=$p.Suggest;Why=("显存约 {0}MB，延长驻留可减少纹理反复驱逐。" -f $hw.VRAM)} }
      return [pscustomobject]@{V=$p.Default;Why=("显存约 {0}MB，余量有限，取默认值。" -f $hw.VRAM)}
    }
    'copyband' {
      if($hw.VRAM -le 0){ return [pscustomobject]@{V=$p.Default;Why='显存未检测到，取默认值 64MB。'} }
      if($hw.VRAM -ge 10000){ return [pscustomobject]@{V=$p.Suggest;Why=("显存约 {0}MB，可放宽单帧拷贝预算。" -f $hw.VRAM)} }
      return [pscustomobject]@{V=$p.Default;Why=("显存约 {0}MB，取默认 64MB 以防止单帧压力过大。" -f $hw.VRAM)}
    }
    'adapter' {
      return [pscustomobject]@{V=$p.Default;Why='取 0。多适配器环境下含义由 D3D 枚举顺序决定。'}
    }
    default {
      return [pscustomobject]@{V=$p.Suggest;Why='引擎层通用参考值，与硬件无关。'}
    }
  }
}

function Show-Warnings([array]$dups,[array]$combos){
  if($dups.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 同名键 ===='
    Write-Host 'SJSON 同名键后者覆盖前者。脚本写入时将统一更新为单行：'
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
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad (Fmt-Val $c.From) 14),(Fmt-Val $c.To)) }
  $risky=@($changes | Where-Object { $_.Tier -eq 'HWSPEC' -or $_.Tier -eq 'CAUTION' })
  $trade=@($changes | Where-Object { $_.Tier -eq 'TRADEOFF' })
  if($trade.Count -gt 0){
    Write-Host ''
    Write-Host ("提示: 含 {0} 项 [取舍]，将改变帧率或画质表现。" -f $trade.Count)
    foreach($t in $trade){ Write-Host ("  - {0}: {1}" -f $t.Key,$t.Cond) }
  }
  if($risky.Count -gt 0){
    Write-Host ''
    Write-Host '==== 警告: 高风险改动 ===='
    Write-Host ("  含 {0} 项 [硬件]/[风险] 改动。取值依赖特定硬件或机制未明确，错误配置可能导致掉帧、破音或驱动崩溃：" -f $risky.Count)
    foreach($r in $risky){ Write-Host ("  - {0}: {1}" -f $r.Key,$r.Cond) }
    Write-Host '  条件见各项的「适用条件」。这些项不参与批量套用。'
    $ans=Read-Key '  输入 yes 继续，其它取消'
    return ($ans -eq 'yes')
  }
  $ok=Read-Key '确认写入? y/N'
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
    Write-Host '  参数联动冲突：取值不满足互斥条件。可使用备份还原。'
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
  if($bad -gt 0){ Write-Host ("  校验失败 {0} 项；备份文件可用于还原。" -f $bad) }
  else{ Write-Host '  已修改项全部校验通过。' }
  Write-Host ''
  Write-Host '==== 改动范围（按行比对）===='
  Write-Host ("  变化 {0} 行  行号 {1}  长度 {2} -> {3}" -f $d.Lines,$d.LineNums,$d.LenA,$d.LenB)
  Write-Host ("  CRLF {0} -> {1}  BOM {2} -> {3}" -f $d.CRLF_A,$d.CRLF_B,$d.BOM_A,$d.BOM_B)
  if($d.Lines -gt $changes.Count){ Write-Host '  警告: 变化行数多于修改项数，请检查意外改动。' }
  if($d.CRLF_A -ne $d.CRLF_B -or $d.BOM_A -ne $d.BOM_B){ Write-Host '  警告: 换行或BOM发生变化，请检查文件。' }
  Write-Host ''
  Write-Host 'Steam 校验或游戏更新会覆盖 settings.ini，更新后需重新运行本工具。'
}

function Show-View([string]$text,[object]$hw,[array]$dups){
  Write-Host ''
  Write-Host ((Pad '类型' 16)+(Pad '参数' 40)+(Pad '当前' 14)+(Pad '参考' 14)+(Pad '影响' 24)+(Pad '置信' 8))
  Write-Host ('-'*116)
  foreach($p in $Params){
    $cur=Get-Val $text $p.Key
    $ls=Get-LocalSuggest $p $hw
    $curShow=if($null -eq $cur){ '(无此键)' }else{ $cur }
    $refShow = if($ls.V -eq '-'){ "($($p.Default))" } else { $ls.V }
    $mark=''
    if($dups.Count -gt 0 -and ($dups.Key -contains $p.Key)){ $mark=' [重复键]' }
    Write-Host ((Pad $TierTag[$p.Tier] 16)+(Pad $p.Key 40)+(Pad (Fmt-Val $curShow) 14)+(Pad (Fmt-Val $refShow) 14)+(Pad $p.Impact 24)+(Pad $p.Conf 8)+$mark)
  }
  Write-Host ''
  Write-Host '? / ？ 查某项的定义与影响；置信度: 确定 > 推定 > 推测 > 猜测。'
}

function Show-Detail([string]$text,[object]$hw){
  while($true){
    Write-Host ''
    Write-Host '输入参数名 / 编号 / 中文关键词（显存、音频、延迟、画质、全屏、线程、取舍）查定义与影响，q 返回菜单'
    $s=Read-Key '查询'
    if($s -eq 'q' -or [string]::IsNullOrWhiteSpace($s)){ return }
    $s=$s.Trim()
    $found=@()
    $n=0
    if([int]::TryParse($s,[ref]$n) -and $n -ge 1 -and $n -le $Params.Count){ $found=@($Params[$n-1]) }
    else { $found=@($Params | Where-Object {
      $hay=($_.Key+' '+$_.Note+' '+$_.Impact+' '+$_.Cond+' '+$_.Src+' '+$_.Conf+' '+$TierTag[$_.Tier]+' '+$_.Default+' '+$_.Suggest)
      $hay.IndexOf($s,[StringComparison]::OrdinalIgnoreCase) -ge 0
    }) }
    if($found.Count -eq 0){ Write-Host '没有匹配的参数'; continue }
    if($found.Count -gt 8){ Write-Host ("匹配 {0} 项，只显示前 8 项；请缩小关键词范围。" -f $found.Count); $found=@($found | Select-Object -First 8) }
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
      Write-Host ("  依据       : {0}" -f $p.Src)
      Write-Host ("  当前 / 默认 / 参考 : {0} / {1} / {2}" -f (Fmt-Val $cur),(Fmt-Val $p.Default),(Fmt-Val $ls.V))
      Write-Host ("  参考值说明 : {0}" -f $ls.Why)
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
  [void]$sb.AppendLine(('GPU: {0} / 显存 {1} MB' -f $hw.GPU,$hw.VRAM))
  [void]$sb.AppendLine(('游戏所在磁盘: {0}' -f $hw.Disk))
  [void]$sb.AppendLine(('同名键: {0}' -f $(if($dups.Count -gt 0){($dups | ForEach-Object { "$($_.Key)x$($_.Count)" }) -join ', '}else{'无'})))
  [void]$sb.AppendLine(('组合冲突: {0}' -f $(if($combos.Count -gt 0){$combos -join '; '}else{'无'})))
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('类型 | 参数 | 当前 | 参考 | 依据 | 影响 | 置信度 | 适用条件 | 定义与影响')
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
  $s=Read-Key '输入编号，回车用第 1 个，q 取消'
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
  if($unknown.Count -gt 0){ Write-Host ("预设包含未知参数，已跳过: {0}" -f ($unknown -join ', ')) }
  if($badVal.Count -gt 0){ Write-Host ("预设包含类型不符的值，已跳过: {0}" -f ($badVal -join ', ')) }
  if($absent.Count -gt 0){ Write-Host ("预设对应键在当前文件中不存在，已跳过: {0}" -f ($absent -join ', ')) }
  Write-Host ''
  Write-Host '预设导入将覆盖下列项（外部数值，匹配关系未校验）：'
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad (Fmt-Val $c.From) 14),(Fmt-Val $c.To)) }
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
    $s=Read-Key '选择'
    if($s -eq 'q'){ return }
    if($s -eq 'd'){
      $x=Read-Key '要删除的编号'
      $n=0
      if([int]::TryParse($x,[ref]$n) -and $n -ge 1 -and $n -le $baks.Count){
        $c=Read-Key ("确认删除 {0}? 输入 yes" -f $baks[$n-1].Name)
        if($c -eq 'yes'){ Remove-Item -LiteralPath $baks[$n-1].FullName -Force; Write-Host '已删除' }
      } else { Write-Host '编号无效' }
      continue
    }
    if($s -eq 'k'){
      $x=Read-Key '保留最近几个（其余删除）'
      $n=0
      if([int]::TryParse($x,[ref]$n) -and $n -ge 1 -and $baks.Count -gt $n){
        $c=Read-Key ("将删除 {0} 个旧备份，输入 yes 确认" -f ($baks.Count-$n))
        if($c -eq 'yes'){ for($i=$n;$i -lt $baks.Count;$i++){ Remove-Item -LiteralPath $baks[$i].FullName -Force }; Write-Host '已清理' }
      } else { Write-Host '数量无效或无需清理' }
      continue
    }
    if($s -eq 'r'){
      if($baks.Count -eq 0){ Write-Host '没有备份'; continue }
      $x=Read-Key '要还原的编号，回车用第 1 个'
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
    $tag=if($t -eq 'TRADEOFF'){ '（本档均为画面项，不参与批量）' }else{ '' }
    Write-Host ("  [{0}] {1}  共 {2} 项{3}" -f ($i+1),(Pad $TierTag[$t] 16),$n,$tag)
  }
  $s=Read-Key '输入编号，q 取消'
  if($s -eq 'q'){ return @() }
  $n=0
  if(-not [int]::TryParse($s,[ref]$n) -or $n -lt 1 -or $n -gt $TierOrder.Count){ Write-Host '编号无效'; return @() }
  $tier=$TierOrder[$n-1]
  if($tier -eq 'TRADEOFF'){ Write-Host '该档全部为画面项，不参与批量；请使用逐项修改。'; return @() }
  $changes=@(); $absent=@(); $noRef=@()
  foreach($p in @($Params | Where-Object { $_.Tier -eq $tier })){
    $ls=Get-LocalSuggest $p $hw
    if($ls.V -eq '-'){ $noRef+=$p.Key; continue }
    $cur=Get-Val $text $p.Key
    if($null -eq $cur){ $absent+=$p.Key; continue }
    if($ls.V -ne $cur){ $changes+=[pscustomobject]@{Key=$p.Key;From=$cur;To=$ls.V;Tier=$p.Tier;Cond=$p.Cond} }
  }
  if($absent.Count -gt 0){ Write-Host ("文件中不存在的键已跳过: {0}" -f ($absent -join ', ')) }
  if($noRef.Count -gt 0){ Write-Host ("无统一参考值的项已跳过: {0}" -f ($noRef -join ', ')) }
  return $changes
}

function Get-AutoChanges([string]$text,[object]$hw){
  $changes=@(); $excluded=@(); $absent=@()
  foreach($p in $Params){
    if($p.Tier -eq 'HWSPEC' -or $p.Tier -eq 'CAUTION'){ $excluded+=$p.Key; continue }
    $ls=Get-LocalSuggest $p $hw
    if($ls.V -eq '-'){ $excluded+=$p.Key; continue }
    $cur=Get-Val $text $p.Key
    if($null -eq $cur){ $absent+=$p.Key; continue }
    if($ls.V -ne $cur){ $changes+=[pscustomobject]@{Key=$p.Key;From=$cur;To=$ls.V;Tier=$p.Tier;Cond=$p.Cond} }
  }
  Write-Host ("批量套用已排除 {0} 项（[硬件]/[风险]、画面项、推测/猜测不参与批量）" -f $excluded.Count)
  if($absent.Count -gt 0){ Write-Host ("文件中不存在的键 {0} 项，已跳过" -f $absent.Count) }
  return $changes
}

function Get-DryRun([string]$path,[string]$text,[array]$changes){
  Write-Host ''
  Write-Host '==== 干跑预览（不写入）===='
  foreach($c in $changes){ Write-Host ("  {0} {1} {2} -> {3}" -f (Pad $TierTag[$c.Tier] 16),(Pad $c.Key 46),(Pad (Fmt-Val $c.From) 14),(Fmt-Val $c.To)) }
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

if($hw.Logical -eq 0){ Write-Host '警告: 硬件检测失败（WMI 可能被禁用），参考值将全部使用保守默认值。' }

$coreTxt = "({0}C{1}T)" -f $hw.Physical,$hw.Logical
$ramTxt  = if($hw.RAM  -gt 0){ "$($hw.RAM) MB"  }else{ '未检测到' }
$vramTxt = if($hw.VRAM -gt 0){ "$($hw.VRAM) MB" }else{ '未检测到' }

Write-Host ''
Write-Host '==== 硬件检测 ===='
Write-Host ("  CPU: {0}  {1}    RAM: {2}" -f $hw.CPUName.Trim(), $coreTxt, $ramTxt)
Write-Host ("  GPU: {0}    VRAM: {1}    游戏所在磁盘: {2}" -f $hw.GPU.Trim(), $vramTxt, $hw.Disk)
Write-Host ("文件: {0} ({1} 字节)" -f $path,([IO.FileInfo]::new($path)).Length)
$text0=Get-IniText $path
if($text0 -notmatch 'stingray_version|project_name'){
  Write-Host '警告: 文件中未发现 stingray_version 或 project_name，可能不是 HD2 的 settings.ini'
  $go=Read-Key '仍要继续? y/N'
  if($go -ne 'y'){ exit 0 }
}
Write-Host '按字节流读写，保留编码、换行与行尾注释；修改前自动备份。'

while($true){
  $text=Get-IniText $path
  $dups=Get-DuplicateKeys $text
  $combos=Get-ComboWarnings $text
  Show-Warnings $dups $combos
  Write-Host ''
  Write-Host '==== 菜单 ===='
  Write-Host '  回车  逐项修改          a  批量套用参考值（排除高风险/画面/依据不足）'
  Write-Host '  t     按分级批量         d  干跑预览（不写入）'
  Write-Host '  v     参数总览           ?  查定义与影响（支持中文）'
  Write-Host '  s     导出只读快照       e  导出预设           i  导入预设'
  Write-Host '  b     备份管理（列/删/清理/还原）          q  退出'
  $mode=Read-Key '选择'
  if($mode -eq 'q'){ break }
  if($mode -eq '?'){ Show-Detail $text $hw; continue }
  if($mode -eq ''){
    $changes=@()
    Write-Host ''
    Write-Host '逐项配置：回车跳过，y 采用参考值（无参考值项不可用），r 恢复默认值，输入数值自定义，q 结束。'
    for($i=0;$i -lt $Params.Count;$i++){
      $p=$Params[$i]
      $cur=Get-Val $text $p.Key
      if($null -eq $cur){
        Write-Host ''
        Write-Host ("[{0,2}/{1,2}] {2} {3}" -f ($i+1),$Params.Count,$TierTag[$p.Tier],$p.Key)
        Write-Host '        文件中不存在该键（旧版本可能缺少对应配置段），已跳过。'
        continue
      }
      $ls=Get-LocalSuggest $p $hw
      Write-Host ''
      Write-Host ("[{0,2}/{1,2}] {2} {3}" -f ($i+1),$Params.Count,$TierTag[$p.Tier],$p.Key)
      Write-Host ("        当前 {0}   默认 {1}   参考 {2}（{3}）   {4} / {5}" -f (Fmt-Val $cur),(Fmt-Val $p.Default),(Fmt-Val $ls.V),$p.Src,$p.Impact,$p.Conf)
      Write-Host ("        定义: {0}" -f $p.Note)
      Write-Host ("        参考值说明: {0}" -f $ls.Why)
      Write-Host ("        适用条件: {0}" -f $p.Cond)
      if($p.Tier -eq 'CAUTION' -or $p.Tier -eq 'HWSPEC'){ Write-Host '        警告: 此项为 [硬件]/[风险] 级别，取值不匹配可能导致掉帧或驱动崩溃。' }
      $in=Read-Key '        选择 [回车跳过 / y 参考 / r 默认 / 自定义 / q 结束]'
      if($in -eq 'q'){ break }
      if([string]::IsNullOrWhiteSpace($in)){ continue }
      $v=$in
      if($in -eq 'y'){
        if($ls.V -eq '-'){ Write-Host '        该项无统一参考值，请输入数值，或按 r 恢复默认值。'; continue }
        $v=$ls.V
      }
      elseif($in -eq 'r'){ $v=$p.Default }
      if(-not (Test-Val $v $p.Default)){
        Write-Host ("        输入「{0}」与该键类型（{1}）不符，已跳过。默认值格式：{2}" -f $v,(Get-ValType $p.Default),$p.Default)
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
Write-Host ('本工具不干预 user_settings.config，不触碰保护项（{0}）。' -f ($Protected -join ' / '))
Write-Host ''