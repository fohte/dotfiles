MCP_DIR := $(abspath ../mcp)
MCP_RENDER := $(MCP_DIR)/render
MCP_INPUTS := $(MCP_DIR)/render.libsonnet $(MCP_RENDER) $(shell $(MCP_RENDER) --inputs)
