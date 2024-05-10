-- Import the busted testing framework
package.path = package.path .. ';./src/?.lua;./lua/?.lua'
local busted = require("busted")

-- Mock the telescope module
local mockTelescope = {
	extensions = {
		live_grep_args = {
			live_grep_args = function(args)
				-- This function will be filled in the tests
			end
		}
	}
}

-- Replace the real telescope module with the mock
package.loaded['telescope'] = mockTelescope

-- Import the pd module, which will now use the mocked telescope
local pd = require("pd_nvim.pd")

-- Test the find_func function
busted.describe("pd.find_func", function()
	busted.it("should call the live_grep_args function with the correct arguments", function()
		-- Fill in the mock function
		mockTelescope.extensions.live_grep_args.live_grep_args = function(args)
			assert.are.same(args, { default_text = '^\\w+\\W.*test_func\\(.*\\)' })
		end

		pd.find_func("test_func")
	end)
end)

-- Test the find_struct function
busted.describe("pd.find_struct", function()
	busted.it("should call the live_grep_args function with the correct arguments", function()
		-- Fill in the mock function
		mockTelescope.extensions.live_grep_args.live_grep_args = function(args)
			assert.are.same(args, { default_text = '^struct\\Wtest_struct\\W\\{' })
		end

		pd.find_struct("test_struct")
	end)
end)

-- Test the find_define_typedef function
busted.describe("pd.find_define_typedef", function()
	busted.it("should call the live_grep_args function with the correct arguments", function()
		-- Fill in the mock function
		mockTelescope.extensions.live_grep_args.live_grep_args = function(args)
			assert.are.same(args, { default_text = '^(typedef\\W\\w+\\W|#define\\W)test_typedef\\W' })
		end

		pd.find_define_typedef("test_typedef")
	end)
end)
