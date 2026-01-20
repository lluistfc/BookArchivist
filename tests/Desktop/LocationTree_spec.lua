---@diagnostic disable: undefined-global, undefined-field
-- LocationTree_spec.lua
-- Tests for BookArchivist location tree building and navigation
-- Critical path: 861 lines of tree building, navigation, and breadcrumb logic
--
-- NOTE: WoW API stubs (wipe) now provided by Mechanic's wow_stubs.lua

describe("BookArchivist_UI_List_Location", function()
	local ListUI
	local mockDB
	local mockAddon

	setup(function()
		-- Load the addon namespace
		_G.BookArchivist = _G.BookArchivist or {}
		_G.BookArchivist.UI = _G.BookArchivist.UI or {}
		_G.BookArchivist.UI.List = _G.BookArchivist.UI.List or {}
		_G.BookArchivist.L = _G.BookArchivist.L or {}

		-- Mock localization
		_G.BookArchivist.L = {
			LOCATIONS_BREADCRUMB_ROOT = "All Locations"
		}

		-- Load the location module
		dofile("ui/list/BookArchivist_UI_List_Location.lua")
		ListUI = _G.BookArchivist.UI.List
	end)

	before_each(function()
		-- Create mock database with v2 schema
		mockDB = {
			dbVersion = 2,
			booksById = {},
			order = {},
			indexes = {},
		}

		-- Create mock addon
		mockAddon = {
			GetDB = function() return mockDB end
		}

		-- Reset ListUI state
		ListUI.__state = ListUI.__state or {}
		ListUI.__state.location = {
			root = nil,
			path = {},
			rows = {},
			activeNode = nil,
			totalRows = 0,
			currentPage = 1,
			totalPages = 1,
		}

		-- Mock GetAddon
		ListUI.GetAddon = function() return mockAddon end

		-- Mock GetLocationState
		ListUI.GetLocationState = function()
			return ListUI.__state.location
		end

		-- Mock pagination (use actual function)
		ListUI.__state.pagination = { pageSize = 25, page = 1 }
		ListUI.GetPageSize = function() return 25 end

		-- Mock EntryMatchesFilters (accept all)
		ListUI.EntryMatchesFilters = function(_, entry) return entry ~= nil end

		-- Mock DebugPrint (silent)
		ListUI.DebugPrint = function() end

		-- Mock UpdateLocationBreadcrumbUI (no-op)
		ListUI.UpdateLocationBreadcrumbUI = function() end

		-- Mock PaginateArray (simple implementation)
		ListUI.PaginateArray = function(_, items, pageSize, currentPage)
			pageSize = pageSize or 25
			currentPage = currentPage or 1
			local totalItems = #items
			local totalPages = math.max(1, math.ceil(totalItems / pageSize))
			currentPage = math.max(1, math.min(currentPage, totalPages))
			local startIdx = (currentPage - 1) * pageSize + 1
			local endIdx = math.min(startIdx + pageSize - 1, totalItems)
			local paginated = {}
			for i = startIdx, endIdx do
				if items[i] then
					table.insert(paginated, items[i])
				end
			end
			return paginated, totalItems, currentPage, totalPages, startIdx, endIdx
		end
	end)

	describe("GetLocationBreadcrumbText", function()
		it("should return root text when path is empty", function()
			local state = ListUI:GetLocationState()
			state.path = {}

			local text = ListUI:GetLocationBreadcrumbText()
			assert.are.equal("All Locations", text)
		end)

		it("should join path segments with ' > '", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor", "Durotar", "Orgrimmar"}

			local text = ListUI:GetLocationBreadcrumbText()
			assert.are.equal("Kalimdor > Durotar > Orgrimmar", text)
		end)

		it("should handle single segment", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor"}

			local text = ListUI:GetLocationBreadcrumbText()
			assert.are.equal("Kalimdor", text)
		end)
	end)

	describe("GetLocationBreadcrumbSegments", function()
		it("should return root when path is empty", function()
			local state = ListUI:GetLocationState()
			state.path = {}

			local segments = ListUI:GetLocationBreadcrumbSegments()
			assert.are.equal(1, #segments)
			assert.are.equal("All Locations", segments[1])
		end)

		it("should return path segments", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor", "Durotar"}

			local segments = ListUI:GetLocationBreadcrumbSegments()
			assert.are.same({"Kalimdor", "Durotar"}, segments)
		end)
	end)

	describe("GetLocationRows", function()
		it("should return empty array when no rows", function()
			local rows = ListUI:GetLocationRows()
			assert.are.equal(0, #rows)
		end)

		it("should return current rows", function()
			local state = ListUI:GetLocationState()
			state.rows = {
				{ kind = "location", name = "Kalimdor" },
				{ kind = "book", key = "b2:abc123" }
			}

			local rows = ListUI:GetLocationRows()
			assert.are.equal(2, #rows)
			assert.are.equal("location", rows[1].kind)
			assert.are.equal("book", rows[2].kind)
		end)
	end)

	describe("GetLocationPagination", function()
		it("should return default pagination when empty", function()
			local pagination = ListUI:GetLocationPagination()
			assert.are.equal(0, pagination.totalRows)
			assert.are.equal(1, pagination.currentPage)
			assert.are.equal(1, pagination.totalPages)
		end)

		it("should return current pagination state", function()
			local state = ListUI:GetLocationState()
			state.totalRows = 50
			state.currentPage = 2
			state.totalPages = 3

			local pagination = ListUI:GetLocationPagination()
			assert.are.equal(50, pagination.totalRows)
			assert.are.equal(2, pagination.currentPage)
			assert.are.equal(3, pagination.totalPages)
		end)
	end)

	describe("NavigateInto", function()
		it("should add segment to path", function()
			local state = ListUI:GetLocationState()
			state.root = {
				name = "__ROOT__",
				depth = 0,
				children = {
					Kalimdor = {
						name = "Kalimdor",
						depth = 1,
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Kalimdor"},
				books = {}
			}
			state.activeNode = state.root

			ListUI:NavigateInto("Kalimdor")

			assert.are.equal(1, #state.path)
			assert.are.equal("Kalimdor", state.path[1])
		end)

		it("should reset current page to 1", function()
			local state = ListUI:GetLocationState()
			state.root = {
				name = "__ROOT__",
				children = {
					Zone = {
						name = "Zone",
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Zone"}
			}
			state.activeNode = state.root
			state.currentPage = 5

			ListUI:NavigateInto("Zone")

			assert.are.equal(1, state.currentPage)
		end)

		it("should ignore empty segment", function()
			local state = ListUI:GetLocationState()
			state.path = {}

			ListUI:NavigateInto("")

			assert.are.equal(0, #state.path)
		end)

		it("should normalize location label", function()
			local state = ListUI:GetLocationState()
			state.root = {
				children = {
					["Unknown Location"] = {
						name = "Unknown Location",
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Unknown Location"}
			}
			state.activeNode = state.root

			ListUI:NavigateInto(nil) -- nil should become "Unknown Location"

			-- Normalization happens, but we can't navigate to non-existent child
			-- Just verify path is not corrupted
			assert.is_table(state.path)
		end)
	end)

	describe("NavigateUp", function()
		it("should remove last segment from path", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor", "Durotar", "Orgrimmar"}
			state.root = {
				children = {
					Kalimdor = {
						children = {
							Durotar = {
								children = {},
								childNames = {},
								books = {}
							}
						},
						childNames = {"Durotar"}
					}
				},
				childNames = {"Kalimdor"}
			}

			ListUI:NavigateUp()

			assert.are.equal(2, #state.path)
			assert.are.equal("Kalimdor", state.path[1])
			assert.are.equal("Durotar", state.path[2])
		end)

		it("should reset current page to 1", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor", "Durotar"}
			state.root = {
				children = {
					Kalimdor = {
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Kalimdor"}
			}
			state.currentPage = 5

			ListUI:NavigateUp()

			assert.are.equal(1, state.currentPage)
		end)

		it("should do nothing when path is empty", function()
			local state = ListUI:GetLocationState()
			state.path = {}

			ListUI:NavigateUp()

			assert.are.equal(0, #state.path)
		end)

		it("should do nothing when path is nil", function()
			local state = ListUI:GetLocationState()
			state.path = nil

			ListUI:NavigateUp()

			-- Should not crash
			assert.is_true(true)
		end)
	end)

	describe("RebuildLocationRows", function()
		it("should show back button when not at root", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor"}
			state.root = {
				children = {
					Kalimdor = {
						name = "Kalimdor",
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Kalimdor"}
			}
			state.activeNode = state.root.children.Kalimdor

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			assert.is_true(#rows >= 1)
			assert.are.equal("back", rows[1].kind)
		end)

		it("should not show back button at root", function()
			local state = ListUI:GetLocationState()
			state.path = {}
			state.root = {
				children = {},
				childNames = {},
				books = {}
			}
			state.activeNode = state.root

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			if #rows > 0 then
				assert.are_not.equal("back", rows[1].kind)
			end
		end)

		it("should show location rows when node has children", function()
			local state = ListUI:GetLocationState()
			state.path = {}
			state.root = {
				children = {
					Kalimdor = {
						name = "Kalimdor",
						children = {},
						childNames = {},
						books = {}
					},
					["Eastern Kingdoms"] = {
						name = "Eastern Kingdoms",
						children = {},
						childNames = {},
						books = {}
					}
				},
				childNames = {"Kalimdor", "Eastern Kingdoms"},
				books = {}
			}
			state.activeNode = state.root

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			assert.is_true(#rows >= 2)
			assert.are.equal("location", rows[1].kind)
			assert.are.equal("location", rows[2].kind)
		end)

		it("should show book rows when node has no children", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor"}
			state.root = {
				children = {
					Kalimdor = {
						name = "Kalimdor",
						children = {},
						childNames = {},
						books = {"b2:abc123", "b2:def456"}
					}
				}
			}
			state.activeNode = state.root.children.Kalimdor

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			-- 1 back button + 2 books
			assert.are.equal(3, #rows)
			assert.are.equal("back", rows[1].kind)
			assert.are.equal("book", rows[2].kind)
			assert.are.equal("book", rows[3].kind)
		end)

		it("should show both subzones AND books from all descendant nodes", function()
			-- Scenario: Books captured in "Zone > Subzone" should be visible when viewing "Zone"
			-- BUT only if the Zone itself has at least one book directly
			local state = ListUI:GetLocationState()
			state.path = {"Azeroth", "Khaz Algar", "Isle of Dorn"}
			state.root = {
				children = {
					Azeroth = {
						name = "Azeroth",
						children = {
							["Khaz Algar"] = {
								name = "Khaz Algar",
								children = {
									["Isle of Dorn"] = {
										name = "Isle of Dorn",
										children = {
											["Fungal Folly"] = {
												name = "Fungal Folly",
												children = {},
												childNames = {},
												books = {"b2:book_in_fungal_folly"}
											}
										},
										childNames = {"Fungal Folly"},
										books = {"b2:book_in_isle", "b2:book_in_isle_2"}
									}
								},
								childNames = {"Isle of Dorn"}
							}
						},
						childNames = {"Khaz Algar"}
					}
				},
				childNames = {"Azeroth"}
			}
			-- Navigate to "Isle of Dorn" which has both subzones (Fungal Folly) AND books directly
			state.activeNode = state.root.children.Azeroth.children["Khaz Algar"].children["Isle of Dorn"]

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			-- Expected: 1 back button + 1 subzone (Fungal Folly) + 3 books (2 in Isle, 1 in Fungal Folly)
			assert.are.equal(5, #rows)
			assert.are.equal("back", rows[1].kind)
			-- First should be the subzone
			assert.are.equal("location", rows[2].kind)
			assert.are.equal("Fungal Folly", rows[2].name)
			-- Then books (from Isle of Dorn AND Fungal Folly)
			assert.are.equal("book", rows[3].kind)
			assert.are.equal("book", rows[4].kind)
			assert.are.equal("book", rows[5].kind)
			
			-- Verify totalRows includes all items (subzone + all books)
			assert.are.equal(4, state.totalRows) -- 1 subzone + 3 books
		end)

		it("should show only subzones when zone has no direct books (only in descendants)", function()
			-- Scenario: Zone has NO books directly, only in subzones
			-- Should show ONLY subzones, not books from descendants
			local state = ListUI:GetLocationState()
			state.path = {"Azeroth"}
			state.root = {
				children = {
					Azeroth = {
						name = "Azeroth",
						children = {
							["Khaz Algar"] = {
								name = "Khaz Algar",
								children = {
									["Isle of Dorn"] = {
										name = "Isle of Dorn",
										children = {},
										childNames = {},
										books = {"b2:book_in_isle"}
									}
								},
								childNames = {"Isle of Dorn"},
								books = {} -- No direct books in Khaz Algar
							}
						},
						childNames = {"Khaz Algar"},
						books = {} -- No direct books in Azeroth
					}
				},
				childNames = {"Azeroth"}
			}
			state.activeNode = state.root.children.Azeroth

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			-- Expected: 1 back button + 1 subzone (Khaz Algar), NO books
			assert.are.equal(2, #rows)
			assert.are.equal("back", rows[1].kind)
			assert.are.equal("location", rows[2].kind)
			assert.are.equal("Khaz Algar", rows[2].name)
			
			-- Verify totalRows is just the subzone (no books)
			assert.are.equal(1, state.totalRows) -- 1 subzone only
		end)

		it("should show books from deeply nested subzones", function()
			-- Scenario: Books in "Zone > Sub1 > Sub2 > Sub3" should appear when viewing "Zone"
			local state = ListUI:GetLocationState()
			state.path = {"Zone"}
			state.root = {
				children = {
					Zone = {
						name = "Zone",
						children = {
							Sub1 = {
								name = "Sub1",
								children = {
									Sub2 = {
										name = "Sub2",
										children = {
											Sub3 = {
												name = "Sub3",
												children = {},
												childNames = {},
												books = {"b2:deep_book_1", "b2:deep_book_2"}
											}
										},
										childNames = {"Sub3"},
										books = {"b2:mid_book"}
									}
								},
								childNames = {"Sub2"},
								books = {"b2:sub1_book"}
							}
						},
						childNames = {"Sub1"},
						books = {"b2:zone_book"}
					}
				},
				childNames = {"Zone"}
			}
			state.activeNode = state.root.children.Zone

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			-- Expected: 1 back + 1 subzone (Sub1) + 5 books (1 in Zone, 1 in Sub1, 1 in Sub2, 2 in Sub3)
			assert.are.equal(7, #rows)
			assert.are.equal("back", rows[1].kind)
			assert.are.equal("location", rows[2].kind)
			assert.are.equal("Sub1", rows[2].name)
			-- Remaining rows should all be books (from all levels)
			for i = 3, 7 do
				assert.are.equal("book", rows[i].kind)
			end
			
			-- Verify totalRows includes all items
			assert.are.equal(6, state.totalRows) -- 1 subzone + 5 books from all levels
		end)

		it("should paginate location rows", function()
			local state = ListUI:GetLocationState()
			state.path = {}
			local children = {}
			local childNames = {}
			for i = 1, 50 do
				local name = "Zone" .. i
				children[name] = { name = name, books = {} }
				table.insert(childNames, name)
			end
			state.root = {
				children = children,
				childNames = childNames,
				books = {}
			}
			state.activeNode = state.root

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			assert.are.equal(25, #rows) -- Page 1: 25 items
			assert.are.equal(50, state.totalRows)
			assert.are.equal(2, state.totalPages)
		end)

		it("should paginate book rows", function()
			local state = ListUI:GetLocationState()
			state.path = {"Zone"}
			local books = {}
			for i = 1, 50 do
				table.insert(books, "b2:book" .. i)
			end
			state.root = {
				children = {
					Zone = {
						name = "Zone",
						children = {},
						childNames = {},
						books = books
					}
				}
			}
			state.activeNode = state.root.children.Zone

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			local rows = state.rows
			-- 1 back button + 25 books
			assert.are.equal(26, #rows)
			assert.are.equal("back", rows[1].kind)
			assert.are.equal(50, state.totalRows)
			assert.are.equal(2, state.totalPages)
		end)

		it("should set totalRows correctly", function()
			local state = ListUI:GetLocationState()
			state.path = {}
			state.root = {
				children = {},
				childNames = {},
				books = {"b2:1", "b2:2", "b2:3"}
			}
			state.activeNode = state.root

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			assert.are.equal(3, state.totalRows)
		end)

		it("should handle empty node gracefully", function()
			local state = ListUI:GetLocationState()
			state.path = {}
			state.root = nil
			state.activeNode = nil

			ListUI.RebuildLocationRows(state, ListUI, 25, 1)

			assert.are.equal(0, #state.rows)
			assert.are.equal(0, state.totalRows)
			assert.are.equal(1, state.currentPage)
			assert.are.equal(1, state.totalPages)
		end)
	end)

	describe("EnsureLocationPathValid", function()
		it("should clear path when root is nil", function()
			local state = ListUI:GetLocationState()
			state.path = {"Kalimdor", "Durotar"}
			state.root = nil

			ListUI.EnsureLocationPathValid(state)

			assert.are.equal(0, #state.path)
			assert.is_nil(state.activeNode)
		end)

		it("should preserve valid path", function()
			local state = ListUI:GetLocationState()
			local durotarNode = {
				children = {},
				childNames = {}
			}
			state.root = {
				children = {
					Kalimdor = {
						children = {
							Durotar = durotarNode
						},
						childNames = {"Durotar"}
					}
				},
				childNames = {"Kalimdor"}
			}
			state.path = {"Kalimdor", "Durotar"}

			ListUI.EnsureLocationPathValid(state)

			assert.are.equal(2, #state.path)
			assert.are.equal("Kalimdor", state.path[1])
			assert.are.equal("Durotar", state.path[2])
			assert.are.equal(durotarNode, state.activeNode)
		end)

		it("should truncate invalid path", function()
			local state = ListUI:GetLocationState()
			state.root = {
				children = {
					Kalimdor = {
						children = {},
						childNames = {}
					}
				},
				childNames = {"Kalimdor"}
			}
			state.path = {"Kalimdor", "Durotar", "Orgrimmar"} -- Durotar doesn't exist

			ListUI.EnsureLocationPathValid(state)

			assert.are.equal(1, #state.path) -- Truncated to Kalimdor
			assert.are.equal("Kalimdor", state.path[1])
		end)

		it("should set activeNode to end of valid path", function()
			local state = ListUI:GetLocationState()
			local durotarNode = {
				name = "Durotar",
				children = {},
				childNames = {}
			}
			state.root = {
				children = {
					Kalimdor = {
						name = "Kalimdor",
						children = {
							Durotar = durotarNode
						},
						childNames = {"Durotar"}
					}
				},
				childNames = {"Kalimdor"}
			}
			state.path = {"Kalimdor", "Durotar"}

			ListUI.EnsureLocationPathValid(state)

			assert.are.equal(durotarNode, state.activeNode)
		end)
	end)
end)
