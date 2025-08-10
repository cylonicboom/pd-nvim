return {
	{
		'pd-nvim',
		dependencies = {
			-- which-key integration
			{ "folke/which-key.nvim" },

			-- Debugging tools
			{ 'mfussenegger/nvim-dap' },
			{ "julianolf/nvim-dap-lldb" },
			{ 'folke/neodev.nvim' },
			{ "rcarriga/nvim-dap-ui" },
			{ "nvim-neotest/nvim-nio" },
			{ "rcarriga/cmp-dap" },
			{ "hrsh7th/nvim-cmp" },

			-- Telescope extensions
			{ 'nvim-telescope/telescope.nvim' },
			{ "nvim-telescope/telescope-live-grep-args.nvim" },
		},
		config = true,
		dev = false,
	},
}
