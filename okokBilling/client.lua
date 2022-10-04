ESX = nil
PlayerData = {}
local primo = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
	PlayerData.job = job
end)

RegisterNetEvent("esx:setOrg")
AddEventHandler("esx:setOrg", function(job)
	PlayerData.org = job
end)

function MyInvoices()
	ESX.TriggerServerCallback("okokBilling:GetInvoices", function(invoices)
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'myinvoices',
			invoices = invoices,
			VAT = Config.VATPercentage
		})			
	end)
end

function SocietyInvoices(society)
	ESX.TriggerServerCallback("okokBilling:GetSocietyInvoices", function(cb, totalInvoices, totalIncome, totalUnpaid, awaitedIncome)
		--if json.encode(cb) ~= '[]' then
			SetNuiFocus(true, true)
			SendNUIMessage({
				action = 'societyinvoices',
				invoices = cb,
				totalInvoices = totalInvoices,
				totalIncome = totalIncome,
				totalUnpaid = totalUnpaid,
				awaitedIncome = awaitedIncome,
				VAT = Config.VATPercentage
			})		
		--else
		--	ESX.ShowNotification("La tua società non ha ancora nessuna Fattura.")
		--	SetNuiFocus(false, false)
		--end
	end, society)
end

RegisterNetEvent('okokBilling:SocietyInvoices', function(society)
	SocietyInvoices(society)
end)

function CreateInvoice(society, societyLabel, target)
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = 'createinvoice',
		society = society,
		target = target,
		societyLabel = societyLabel
	})
end

RegisterNetEvent('okokBilling:CreateInvoice')
AddEventHandler('okokBilling:CreateInvoice', function(society, societyLabel, target)
	CreateInvoice(society, societyLabel, target)
end)

RegisterCommand(Config.InvoicesCommand, function()
	local isAllowed = false
	local jobName = ""
	for k, v in pairs(Config.AllowedSocieties) do
		if v == PlayerData.job.name then
			jobName = v
			isAllowed = true
		end
	end

	if Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.grade_name == "boss" and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.grade_name ~= "boss" and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = true
		})
	elseif not Config.OnlyBossCanAccessSocietyInvoices and isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = true,
			create = true
		})
	elseif not isAllowed then
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'mainmenu',
			society = false,
			create = false
		})
	end
end, false)

RegisterNUICallback("action", function(data, cb)
	if data.action == "close" then
		SetNuiFocus(false, false)
	elseif data.action == "payInvoice" then
		TriggerServerEvent("okokBilling:PayInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "cancelInvoice" then
		TriggerServerEvent("okokBilling:CancelInvoice", data.invoice_id)
		SetNuiFocus(false, false)
	elseif data.action == "createInvoice" then
		TriggerServerEvent("okokBilling:CreateInvoice", data)
		ESX.ShowNotification("Hai inviato una fattura di: "..data.invoice_value.."$")
		
		SetNuiFocus(false, false)
	elseif data.action == "missingInfo" then
		ESX.ShowNotification("Devi compilare tutti i campi!")
	elseif data.action == "negativeAmount" then
		ESX.ShowNotification("Devi mettere un importo valido!")
	elseif data.action == "mainMenuOpenMyInvoices" then
		MyInvoices()
	elseif data.action == "mainMenuOpenSocietyInvoices" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerData.job.name then
				if Config.OnlyBossCanAccessSocietyInvoices and PlayerData.job.grade_name == "boss" then
					SocietyInvoices(PlayerData.job.label)
				elseif not Config.OnlyBossCanAccessSocietyInvoices then
					SocietyInvoices(PlayerData.job.label)
				elseif Config.OnlyBossCanAccessSocietyInvoices then
					ESX.ShowNotification("Only the boss can access the society invoices.")
				end
			end
		end
	elseif data.action == "mainMenuOpenCreateInvoice" then
		for k, v in pairs(Config.AllowedSocieties) do
			if v == PlayerData.job.name then
				CreateInvoice(PlayerData.job.label)
			end
		end
	end
end)