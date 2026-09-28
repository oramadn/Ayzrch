-- The clock widget's strftime tokens have no ordinal day, so the text is built here.
local function ordinal(day)
  local lastTwo = day % 100
  if lastTwo >= 11 and lastTwo <= 13 then
    return day .. "th"
  end
  local suffixes = { "st", "nd", "rd" }
  return day .. (suffixes[day % 10] or "th")
end

function update()
  noctalia.setUpdateInterval(1000)
  local now = os.date("*t")
  barWidget.setText(os.date("%H:%M") .. "  " .. ordinal(now.day) .. " of " .. os.date("%b"))
end
