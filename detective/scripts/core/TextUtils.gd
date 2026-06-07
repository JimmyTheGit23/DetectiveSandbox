class_name TextUtils
## 文本显示工具：在显示层过滤舞台指示，保留原始数据不动。
## 过滤的括号内容（如"（低声）"）可用于未来动画/表情系统。

static var _re_stage_dir: RegEx = null

## 过滤中文括号内的舞台指示文本（（低声）、（叹气）等）
## 仅用于显示层，不影响 CSV 数据源。
static func strip_stage_directions(text: String) -> String:
	if _re_stage_dir == null:
		_re_stage_dir = RegEx.new()
		_re_stage_dir.compile("（[^）]*）")
	var result := _re_stage_dir.sub(text, "", true)
	# 清理可能残留的多余空格
	result = result.replace("  ", " ").strip_edges()
	return result
