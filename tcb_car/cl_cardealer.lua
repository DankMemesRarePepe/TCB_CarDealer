/*---------------------------------------------------------------------------
	
	Creator: TheCodingBeast - TheCodingBeast.com
	This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
	
---------------------------------------------------------------------------*/

--[[---------------------------------------------------------
	Fonts
-----------------------------------------------------------]]
for i=0,24 do

	--> Size
	local size = 10+i

	--> Font
	surface.CreateFont("TCBDealer_"..size, {
		font = "Trebuchet24",
		size = size,
	})

end

--[[---------------------------------------------------------
	Chat Text
-----------------------------------------------------------]]
local function chatText()
	chat.AddText(Color(52, 152, 219), "[Dealer]", Color(255, 255, 255), " "..net.ReadString())
end
net.Receive("TCBDealerChat", chatText)


--[[---------------------------------------------------------
	Derma Blur - Credits: Mrkrabz
-----------------------------------------------------------]]
local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
	local x, y = panel:LocalToScreen(0, 0)
	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(blur)
	for i = 1, 3 do
		blur:SetFloat("$blur", (i / 3) * (amount or 6))
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
	end
end

--[[---------------------------------------------------------
	Dealer Menu
-----------------------------------------------------------]]
local function carDealer()

	--> Variables
	local vehiclesTable = TCBDealer.vehicleTable
	local ownedTable 	= net.ReadTable()

	local dealerID = net.ReadInt(32)

	local w = 450
	local h = 602

	--> Sort
	//table.sort(vehiclesTable,)

	--> Frame
	local frame = vgui.Create("DFrame")
	frame:SetPos(ScrW()/2-w/2, ScrH())
	frame:SetSize(w, h)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	frame:MoveTo(ScrW()/2-w/2, ScrH()/2-h/2, 0.2, 0, -1)
	
	frame.Paint = function(pnl, w, h)

		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
		draw.RoundedBox(0, 1, 1, w-2, h-2, Color(255, 255, 255, 255))

		draw.RoundedBox(0, 1, 1, w-2, 40, Color(63, 81, 181, 255))
		draw.SimpleText("TCB - Car Dealer", "TCBDealer_24", 11, 41-20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	end

	--> Close
	local close = vgui.Create("DButton", frame)
	close:SetPos(w-65-7, 41/2-24/2)
	close:SetSize(65, 26)
	close:SetText("")

	close.DoClick = function()

		frame:MoveTo(ScrW()/2-w/2, ScrH(), 0.2, 0, -1, function()
			frame:Remove()
		end)

	end

	close.Paint = function(pnl, w, h)

		draw.RoundedBox(3, 0, 0, w, h, Color(244, 67, 54, 255))
		draw.SimpleText("x", "TCBDealer_24", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if close.Hovered then
			draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
		end

	end

	--> Panel
	local panel = vgui.Create("DScrollPanel", frame)
	panel:SetPos(1, 41)
	panel:SetSize(w-2, h-2-40)

	panel.VBar.Paint 			= function( pnl, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 50) ) end 
	panel.VBar.btnUp.Paint 		= function( pnl, w, h ) draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 0, 0, 0, 25 ) ) draw.DrawText( "▲", "HudHintTextSmall", 3, 2, Color( 255, 255, 255, 255 ) ) end
	panel.VBar.btnDown.Paint 	= function( pnl, w, h ) draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 0, 0, 0, 25 ) ) draw.DrawText( "▼", "HudHintTextSmall", 3, 2, Color( 255, 255, 255, 255 ) ) end
	panel.VBar.btnGrip.Paint 	= function( pnl, w, h ) draw.RoundedBox( 4, 3, 2, w - 6, h - 4, Color( 63, 81, 181, 255 ) ) end

	--> Slide EWW :(
	local slide = vgui.Create("DPanel", panel)
	slide:SetPos(0, 0)
	slide:SetSize(1, panel:GetTall()+1)

	--> Vehicles
	local count = 0
	local posY = 0
	for k,v in SortedPairsByMemberValue(vehiclesTable, "price", true) do

		--> Check
		if v.customCheck and !v.customCheck(LocalPlayer()) then continue end

		--> Count
		count = count+1;

		--> Vehicle Panel
		local vehicle = vgui.Create("DPanel", panel)
		vehicle:SetPos(0, posY)
		vehicle:SetSize((w-2)-16, 80)
		vehicle.count = count

		vehicle.Paint = function(pnl, w, h)

			--> Stripe
			if math.mod(vehicle.count, 2) == 0 then
				draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 15))
			end

			--> Model
			draw.RoundedBox(2, 4, 4, h-8, h-8, Color(0, 0, 0, 40))

			--> Name
			draw.SimpleText(v.name, "TCBDealer_24", w/2-15, 25, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			--> Price
			draw.SimpleText("Price: "..DarkRP.formatMoney(v.price), "TCBDealer_22", w/2-15, 55, Color(0, 0, 0, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		end

		--> Model Preview
		local model = vgui.Create("DModelPanel", vehicle)
		model:SetSize(vehicle:GetTall()-8, vehicle:GetTall()-8)
		model:SetPos(4, 4)
		model:SetModel(v.mdl)
		model:SetColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), 255))
		model:SetCamPos(Vector(150, -100, 50))

		--> Buttons
		if !table.HasValue(ownedTable, k) then

			--> Purchase
			local purchase = vgui.Create("DButton", vehicle)
			purchase:SetSize(100, vehicle:GetTall()/2-6)
			purchase:SetPos(vehicle:GetWide()-104, 4)
			purchase:SetText("")

			purchase.DoClick = function()
				net.Start("TCBDealerPurchase")
					net.WriteString(k)
				net.SendToServer(LocalPlayer())

				frame:MoveTo(ScrW()/2-w/2, ScrH(), 0.2, 0, -1, function()
					frame:Remove()
				end)
			end

			purchase.Paint = function(pnl, w, h)

				draw.RoundedBox(3, 0, 0, w, h, Color(46, 204, 113, 255))
				draw.SimpleText("Purchase", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if purchase.Hovered then
					draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
				end

			end

			--> Preview
			local preview = vgui.Create("DButton", vehicle)
			preview:SetSize(100, vehicle:GetTall()/2-6)
			preview:SetPos(vehicle:GetWide()-104, purchase:GetTall()+8)
			preview:SetText("")

			preview.DoClick = function()
				net.Start("TCBDealerSpawn")
					net.WriteString(k)
					net.WriteInt(dealerID, 32)
					net.WriteBool(true)
				net.SendToServer(LocalPlayer())

				frame:MoveTo(ScrW()/2-w/2, ScrH(), 0.2, 0, -1, function()
					frame:Remove()
				end)
			end

			preview.Paint = function(pnl, w, h)

				draw.RoundedBox(3, 0, 0, w, h, Color(52, 152, 219, 255))
				draw.SimpleText("Test Drive", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if preview.Hovered then
					draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
				end

			end

		else

			--> Spawn
			local spawn = vgui.Create("DButton", vehicle)
			spawn:SetSize(100, vehicle:GetTall()/2-6)
			spawn:SetPos(vehicle:GetWide()-104, 4)
			spawn:SetText("")

			spawn.DoClick = function()
				net.Start("TCBDealerSpawn")
					net.WriteString(k)
					net.WriteInt(dealerID, 32)
					net.WriteBool(false)
				net.SendToServer(LocalPlayer())

				frame:MoveTo(ScrW()/2-w/2, ScrH(), 0.2, 0, -1, function()
					frame:Remove()
				end)
			end

			spawn.Paint = function(pnl, w, h)

				draw.RoundedBox(3, 0, 0, w, h, Color(46, 204, 113, 255))
				draw.SimpleText("Spawn", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if spawn.Hovered then
					draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
				end

			end

			--> Sell
			local sell = vgui.Create("DButton", vehicle)
			sell:SetSize(100, vehicle:GetTall()/2-6)
			sell:SetPos(vehicle:GetWide()-104, spawn:GetTall()+8)
			sell:SetText("")

			sell.DoClick = function()

				local cover = vgui.Create("DPanel", frame)
				cover:SetSize(w, h)
				cover:SetPos(0, 0)

				cover.Paint = function(pnl, w, h)

					draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 150))
					DrawBlur(pnl, 1)

				end

				local coverFront = vgui.Create("DPanel", cover)
				coverFront:SetSize(cover:GetWide(), 100)
				coverFront:SetPos(-500, 40+((cover:GetTall()-40)/2-(100/2)))
				coverFront:MoveTo(0, 40+((cover:GetTall()-40)/2-(100/2)), 0.2)

				coverFront.Paint = function(pnl, w, h)

					draw.RoundedBox(0, 0, 0, w, h, Color(63, 81, 181, 255))

					draw.SimpleText("Are you sure you want to sell this vehicle for "..DarkRP.formatMoney(v.price*(TCBDealer.settings.salePercentage/100)).."?", "TCBDealer_22", w/2, 25, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				end

				--> Yes
				local yes = vgui.Create("DButton", coverFront)
				yes:SetSize(coverFront:GetWide()/2-30, 30)
				yes:SetPos(20, 50)
				yes:SetText("")

				yes.DoClick = function()
					net.Start("TCBDealerSell")
						net.WriteString(k)
					net.SendToServer(LocalPlayer())

					frame:MoveTo(ScrW()/2-w/2, ScrH(), 0.2, 0, -1, function()
						frame:Remove()
					end)
				end

				yes.Paint = function(pnl, w, h)

					draw.RoundedBox(3, 0, 0, w, h, Color(231, 76, 60, 255))
					draw.SimpleText("Yes", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

					if yes.Hovered then
						draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
					end

				end

				--> Cancel
				local cancel = vgui.Create("DButton", coverFront)
				cancel:SetSize(coverFront:GetWide()/2-30, 30)
				cancel:SetPos(40+yes:GetWide(), 50)
				cancel:SetText("")

				cancel.DoClick = function()
					coverFront:MoveTo(-500, 40+((cover:GetTall()-40)/2-(100/2)), 0.2, 0, -1, function()
						cover:Remove()
					end)
				end

				cancel.Paint = function(pnl, w, h)

					draw.RoundedBox(3, 0, 0, w, h, Color(46, 204, 113, 255))
					draw.SimpleText("Cancel", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

					if cancel.Hovered then
						draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
					end

				end

			end

			sell.Paint = function(pnl, w, h)

				draw.RoundedBox(3, 0, 0, w, h, Color(231, 76, 60, 255))
				draw.SimpleText("Sell ("..DarkRP.formatMoney(v.price*(TCBDealer.settings.salePercentage/100))..")", "DermaDefaultBold", w/2, h/2-1, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if sell.Hovered then
					draw.RoundedBox(3, 0, 0, w, h, Color(255, 255, 255, 6))
				end

			end

		end

		--> Position
		posY = posY + vehicle:GetTall()

	end

end
net.Receive("TCBDealerMenu", carDealer)