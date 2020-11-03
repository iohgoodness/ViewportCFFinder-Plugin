local toolbar = plugin:CreateToolbar('CF Finder')
local viewportAssist = toolbar:CreateButton("Viewport Assist", 'FIND relative angles for viewport frames and objects.', "rbxassetid://4459262762")

local UserInputService = game:GetService('UserInputService')
local ChangeHistoryService = game:GetService('ChangeHistoryService')
local HttpService = game:GetService('HttpService')
local Selection = game:GetService('Selection')

local toSaveStr = ''
local enterConn = nil
local saveConn = nil
local pluginClicked = false

local function SaveFile(text, filename)
    local Script = Instance.new("Script",game.Workspace)
    Script.Source = text
    Script.Name = "SaveFile"
    Selection:Set({Script})
    plugin:PromptSaveSelection(filename)
    Script:Remove()
end

local itemFrame = nil
local saveBtn = nil
local scrollingFrame = nil

local function makeUI()
    
    local PluginUI = Instance.new("ScreenGui")
    local ScrollingFrame = Instance.new("ScrollingFrame")
    local UIListLayout = Instance.new("UIListLayout")
    local Frame = Instance.new("Frame")
    local ModelName = Instance.new("TextLabel")
    local RemoveFrame = Instance.new("TextButton")
    local ViewportFrame = Instance.new("ViewportFrame")
    local getcf = Instance.new("TextLabel")
    local TextButton = Instance.new("TextButton")

    --Properties:

    PluginUI.Name = "PluginUI"
    PluginUI.Parent = game.StarterGui
    PluginUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    ScrollingFrame.Parent = PluginUI
    ScrollingFrame.Active = true
    ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ScrollingFrame.Position = UDim2.new(0.725130916, 0, 0.0764563084, 0)
    ScrollingFrame.Size = UDim2.new(0.22617802, 0, 0.62718451, 0)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 16, 0)
    ScrollingFrame.ScrollBarThickness = 8
    
    scrollingFrame = ScrollingFrame

    UIListLayout.Parent = ScrollingFrame
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    Frame.Parent = ScrollingFrame
    Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Frame.Size = UDim2.new(0.980000019, 0, 0, 140)

    ModelName.Name = "ModelName"
    ModelName.Parent = Frame
    ModelName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ModelName.Size = UDim2.new(0.300000012, 0, 1, 0)
    ModelName.Font = Enum.Font.GothamSemibold
    ModelName.Text = "Wisp"
    ModelName.TextColor3 = Color3.fromRGB(0, 0, 0)
    ModelName.TextScaled = true
    ModelName.TextSize = 50.000
    ModelName.TextWrapped = true

    RemoveFrame.Name = "RemoveFrame"
    RemoveFrame.Parent = Frame
    RemoveFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    RemoveFrame.Position = UDim2.new(0.75, 0, 0, 0)
    RemoveFrame.Size = UDim2.new(0.25, 0, 1, 0)
    RemoveFrame.Font = Enum.Font.GothamSemibold
    RemoveFrame.Text = "X"
    RemoveFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
    RemoveFrame.TextSize = 14.000

    ViewportFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ViewportFrame.Parent = Frame
    ViewportFrame.Position = UDim2.new(0.300000012, 0, 0, 0)
    ViewportFrame.Size = UDim2.new(0.45, 0, 1, 0)

    getcf.Name = "getcf"
    getcf.Parent = Frame
    getcf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    getcf.Size = UDim2.new(0.300000012, 0, 1, 0)
    getcf.Visible = false
    getcf.Font = Enum.Font.GothamSemibold
    getcf.Text = "Wisp"
    getcf.TextColor3 = Color3.fromRGB(0, 0, 0)
    getcf.TextScaled = true
    getcf.TextSize = 50.000
    getcf.TextWrapped = true

    TextButton.Parent = PluginUI
    TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextButton.Position = UDim2.new(0.724476337, 0, 0.702669919, 0)
    TextButton.Size = UDim2.new(0.226832539, 0, 0.0446601845, 0)
    TextButton.Font = Enum.Font.GothamSemibold
    TextButton.Text = "Export"
    TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextButton.TextScaled = true
    TextButton.TextSize = 14.000
    TextButton.TextWrapped = true
    
    saveBtn = TextButton
    
    itemFrame = Frame:Clone()
    Frame:Destroy()
end

local function createNewFrame(modelName, modelCF, camCF, selectedModel)
    local newFrame = itemFrame:Clone()
    newFrame.RemoveFrame.MouseButton1Click:Connect(function()
        newFrame:Destroy()
    end)
    newFrame.ModelName.Text = modelName
    local offset = modelCF:toObjectSpace(camCF)
    -- camCF = modelCF * offset
    newFrame.getcf.Text = tostring(offset)
    
    local viewportCamera = Instance.new("Camera")
    newFrame.ViewportFrame.CurrentCamera = viewportCamera
    viewportCamera.Parent = newFrame.ViewportFrame
    
    local modelClone = selectedModel:Clone()
    modelClone.Parent = newFrame.ViewportFrame
    
    viewportCamera.CFrame = selectedModel.PrimaryPart.CFrame * offset
    
    newFrame.Parent = scrollingFrame
end

viewportAssist.Click:Connect(function()
    pluginClicked = not pluginClicked
    if not pluginClicked then
        if enterConn then enterConn:Disconnect() end
        if saveConn then saveConn:Disconnect() end
        if game.StarterGui:FindFirstChild('PluginUI') then game.StarterGui:FindFirstChild('PluginUI').Enabled = false end
    else
        if game.StarterGui:FindFirstChild('PluginUI') == nil then makeUI() end
        enterConn = UserInputService.InputBegan:connect(function(inputObject, gameProcessedEvent)	
            if inputObject.KeyCode == Enum.KeyCode.Return then
                local modelName = nil
                local modelCF   = nil
                local selectedModel = nil
                local camCF     = workspace.CurrentCamera.CFrame
                
                local selectedObjects = Selection:Get()
                local parent = workspace
                for k,selected in pairs(selectedObjects) do
                    if selected:IsA'Model' then
                        if selected.PrimaryPart then
                            modelName = selected.Name
                            selectedModel = selected
                            modelCF = selected:GetPrimaryPartCFrame()
                        else warn 'Needs a primary part!' end
                        break
                    end
                end
                
                if modelCF and modelName and camCF then
                    createNewFrame(modelName, modelCF, camCF, selectedModel)
                end
            end
        end)
        
        game.StarterGui:FindFirstChild('PluginUI').Enabled = true
        local deb = false
        saveConn = saveBtn.MouseButton1Click:Connect(function()
            if not deb then
                deb = true
                local totalOutput = 'local offsets = {\n'
                --# O(N^2)
                local hasDuplicate = false
                for index1,frame1 in pairs(scrollingFrame:GetChildren()) do
                    for index2,frame2 in pairs(scrollingFrame:GetChildren()) do
                        if index1 ~= index2 then
                            if frame1:IsA'Frame' and frame2:IsA'Frame' then
                                local modelName1 = frame1.ModelName.Text
                                local modelName2 = frame2.ModelName.Text
                                if modelName1 == modelName2 then
                                    hasDuplicate = true
                                    break
                                end
                            end
                        end
                    end
                    if hasDuplicate then break end
                end
                if not hasDuplicate then
                    for k,frame in pairs(scrollingFrame:GetChildren()) do
                        if frame:IsA'Frame' then
                            local modelName = frame.ModelName.Text
                            local cfRelative = frame.getcf.Text
                            
                            
                            
                            totalOutput = totalOutput .. ("\t['%s'] = cfnew(%s),\n"):format(modelName, cfRelative)
                        end
                    end
                    totalOutput = totalOutput .. '}'
                    SaveFile(totalOutput, 'output.txt')
                else
                    coroutine.wrap(function()
                        saveBtn.Text = 'Remove duplicates before exporting!'
                        wait(2)
                        saveBtn.Text = 'Export'
                    end)()
                end
                wait(2)
                deb = false
            end
        end)
    end
    ChangeHistoryService:SetWaypoint('undo assist')
end)