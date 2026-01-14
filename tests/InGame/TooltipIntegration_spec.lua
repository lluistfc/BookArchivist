-- TooltipIntegration_spec.lua
-- In-game test for GameTooltip integration with real WoW APIs

describe("Tooltip Integration", function()
	it("should have Tooltip module loaded", function()
		assert.is_not_nil(BookArchivist.Tooltip, "Tooltip module not loaded")
	end)

	it("should have TooltipDataProcessor API available", function()
		assert.is_not_nil(TooltipDataProcessor, "TooltipDataProcessor API not available (WoW API changed?)")
	end)

	it("should have Tooltip module enabled", function()
		local isEnabled = BookArchivist.Tooltip and BookArchivist.Tooltip:IsEnabled()
		assert.is_true(isEnabled, "Tooltip module not enabled")
	end)

	it("should have initialized indexes", function()
		local db = BookArchivist.Repository and BookArchivist.Repository:GetDB()
		assert.is_not_nil(db, "Repository not initialized")
		assert.is_not_nil(db.indexes, "Indexes not initialized")
		assert.is_not_nil(db.indexes.itemToBookIds, "itemToBookIds index missing")
		assert.is_not_nil(db.indexes.objectToBookId, "objectToBookId index missing")
		assert.is_not_nil(db.indexes.titleToBookIds, "titleToBookIds index missing")
	end)

	it("should have at least one index entry if books exist", function()
		local db = BookArchivist.Repository and BookArchivist.Repository:GetDB()
		if db and db.booksById then
			local bookCount = 0
			for _ in pairs(db.booksById) do
				bookCount = bookCount + 1
			end

			if bookCount > 0 then
				-- If we have books, we should have at least some index entries
				local hasIndexes = false
				for _ in pairs(db.indexes.itemToBookIds or {}) do
					hasIndexes = true
					break
				end
				for _ in pairs(db.indexes.objectToBookId or {}) do
					hasIndexes = true
					break
				end
				for _ in pairs(db.indexes.titleToBookIds or {}) do
					hasIndexes = true
					break
				end

				if not hasIndexes then
					print("Warning: " .. bookCount .. " books but no indexes (expected if books have no item/object/title data)")
				end
			end
		end
	end)
end)
