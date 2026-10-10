local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/library.lua"))()
local ign = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/ignore.lua"))()
local vis = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimhev/Dimhev/main/Doors/visuals.lua"))()

-- Создание главного окна
local wnd = Library:CreateWindow({
	Title = "DIMHEV HUB",
	SubTitle = "Doors Edition"
})

-- ==================== ВКЛАДКА 1: СУЩНОСТИ ==================== --
local tab_entities = wnd:CreateTab("Entities")

tab_entities:CreateSection("Basic Modifiers")

tab_entities:CreateToggle("Delete A-90", false, function(val)
	ign.a90(val)
end, "Полностью удаляет механику появления A-90")

tab_entities:CreateToggle("Delete Screech", false, function(val)
	ign.screech(val)
end, "Автоматически нейтрализует Screech в тёмных комнатах")

tab_entities:CreateToggle("Ignore Giggle", false, function(val)
	ign.giggle(val)
end, "Игнорирует потолочных Giggle")

tab_entities:CreateToggle("Ignore Snare", false, function(val)
	ign.snare(val)
end, "Предотвращает срабатывание напольных ловушек (Snare)")

tab_entities:CreateToggle("Ignore Dupe", false, function(val)
	ign.dupe(val)
	vis.dupe(val)
end, "Игнорирует урон от фальшивых дверей и подсвечивает их")

tab_entities:CreateToggle("Ignore Eyes & Lookman", false, function(val)
	ign.eyes(val)
end, "Позволяет смотреть на Eyes и Lookman без получения урона")

tab_entities:CreateSection("Experimental")

-- Красивое оформление предупреждения вместо сырого текста
tab_entities:CreateParagraph(
	"⚠️ Предупреждение о нестабильности",
	"Эта функция является экспериментальной. Возможны просадки пинга и рассинхронизация сети. Полная неуязвимость не гарантируется."
)

tab_entities:CreateToggle("Ignore Rush & Ambush", false, function(val)
	ign.rush(val)
end, "Попытка блокировки урона от проносящихся сущностей")


-- ==================== ВКЛАДКА 2: ДВИЖЕНИЕ ==================== --
local tab_movement = wnd:CreateTab("Movement")

tab_movement:CreateSection("Speed Control")

tab_movement:CreateToggle("Speed Boost", false, function(val)
	ign.speed(val)
end, "Включает модификатор скорости передвижения")

tab_movement:CreateSlider("Speed Value", 0, 50, 15, function(val)
	ign.set_speed(val)
end)


-- ==================== ВКЛАДКА 3: НАСТРОЙКИ И ИНФО ==================== --
local tab_settings = wnd:CreateTab("Settings")

tab_settings:CreateSection("Управление интерфейсом")

tab_settings:CreateParagraph(
	"Горячая клавиша",
	"Нажмите [RightShift] на клавиатуре, чтобы открыть или скрыть интерфейс в любое время."
)

tab_settings:CreateButton("Выгрузить скрипт (Unload)", function()
	lib:Notify({ Title = "Unload", Content = "Скрипт выгружается...", Duration = 1.5 })
	task.wait(0.5)
	wnd.ScreenGui:Destroy()
end)


-- ==================== ОБРАБОТЧИК ЗАКРЫТИЯ ==================== --
wnd.ScreenGui.Destroying:Connect(function()
	ign.cleanup()
	vis.cleanup()
end)

-- Уведомление об успешной загрузке
lib:Notify({
	Title = "Dimhev Hub",
	Content = "Конфигурация успешно применена!",
	Duration = 3
})
