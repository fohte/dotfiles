local window = {}

function window:resizeWindow(fn)
  local window = hs.window.focusedWindow()
  local f = window:frame()
  local max = window:screen():frame()

  fn(f, max)

  window:setFrame(f)
end

-- 1/2 of the left side
function window:first_half(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.w = math.floor(max.w / 2)
  return r
end

-- 1/2 of the right side
function window:last_half(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.x = math.floor(max.x + max.w / 2)
  r.w = math.floor(max.w / 2)
  return r
end

-- 1/3 of the left side
function window:first_third(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.w = math.floor(max.w / 3)
  return r
end

-- 1/3 of the right side
function window:last_third(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.x = math.floor(max.x + max.w / 3 * 2)
  r.w = math.floor(max.w / 3)
  return r
end

-- 2/3 of the left side
function window:first_two_thirds(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.w = math.floor(max.w / 3 * 2)
  return r
end

-- 2/3 of the right side
function window:last_two_thirds(max)
  local r = hs.geometry.rect(max.x, max.y, max.w, max.h)
  r.x = math.floor(max.x + max.w / 3)
  r.w = math.floor(max.w / 3 * 2)
  return r
end

function window:copyRect(f, new)
  f.x = new.x
  f.y = new.y
  f.w = new.w
  f.h = new.h
end

return window
