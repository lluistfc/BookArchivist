local BA = BookArchivist
BA.UI = BA.UI or {}

local Metrics = {
	PAD_OUTER = 12,
	PAD_INSET = 11,
	GAP_XS = 4,
	GAP_S = 6,
	GAP_M = 10,
	GAP_L = 14,
	HEADER_LEFT_SAFE_X = 54,
	HEADER_LEFT_W = 260,
	HEADER_CENTER_BIAS_Y = 2,
	HEADER_H = 90,
	LIST_HEADER_H = 34,
	LIST_TOPBAR_H = 28,
	LIST_TIP_H = 20,
	LIST_INFO_H = 18,
	READER_HEADER_H = 54,
	READER_ACTIONS_W = 140,
	ROW_H = 44,
	BTN_H = 22,
	BTN_W = 100,
	HEADER_RIGHT_STACK_W = 110,
	HEADER_RIGHT_GUTTER = 12,
	SCROLLBAR_GUTTER = 18,
	ROW_PAD_L = 10,
	ROW_PAD_R = 10,
	ROW_PAD_T = 6,
	ROW_HILITE_INSET = 2,
	ROW_EDGE_W = 3,
	SEPARATOR_W = 10,
	SEPARATOR_GAP = 6,
}

-- Legacy aliases so older code keeps functioning while everything migrates.
Metrics.PAD = Metrics.PAD_OUTER
Metrics.GUTTER = Metrics.GAP_M
Metrics.SUBHEADER_H = Metrics.LIST_HEADER_H

BA.UI.Metrics = Metrics
return Metrics
