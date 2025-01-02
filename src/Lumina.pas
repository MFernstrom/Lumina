{===============================================================================
  _                  _
 | |    _  _  _ __  (_) _ _   __ _ ™
 | |__ | || || '  \ | || ' \ / _` |
 |____| \_,_||_|_|_||_||_||_|\__,_|
        Local Generative AI

 Copyright © 2024-present tinyBigGAMES™ LLC
 All Rights Reserved.

 https://github.com/tinyBigGAMES/Lumina

 BSD 3-Clause License

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 -----------------------------------------------------------------------------
 
 This project uses the following open-source libraries:
  * llama.cpp - https://github.com/ggerganov/llama.cpp
 
 -----------------------------------------------------------------------------
 
 Usage Notes:
 ============
 
 * Obtaining Models:
   There’s a link to the model card where you can download the Gemma model.
   The "Any GGUF Model" link points to it. This is considered an
   SLM (Small Language Model), so you can download the 8-bit quantized
   version (Q8_0). For larger models, **Q4** is usually a better choice.

 * GPU Usage and Model Loading:
   If you want to use the GPU, ensure your graphics card has enough VRAM to
   hold both the model and the context (any GPU that supports Vulkan is
   compatible). You can control how many GPU layers to use with the
   `AGPULayers` parameter in the `LoadModel` method.
   - Setting `AGPULayers` to **-1** (default) uses all layers.
   - If the model is too large for your GPU, you can offload layers to RAM by
     setting `AGPULayers` to **0** or a lower number.

 * Model Availability:
   The models are too large to be stored in the repository (2GB or more,
   depending on the model and quantization). Hugging Face, often considered the
   "GitHub for LLMs," hosts these models. Any GGUF model supported by
   llama.cpp should work. The model card will typically specify the minimum
   version of `llama.cpp` required. **Lumina** is always kept up to date with
   these specifications.

 * Customization and Callbacks:
   Several callbacks can be set to customize behavior:
   - Cancel Callback  : Allows you to control how to exit the inference loop.
   - Info Callback    : Displays model information as it loads.
   - Progress Callback: Reports the percentage of the model that has been
     loaded.
   - NextToken Callback: Sends each generated token. If not set, output will
     simply display in the current console.

 * Functionality and Future Updates:
   Currently, the system supports **simple text inference**, handling one
   question at a time. Future updates will expand to include:
   - Chat functionality: Manage system and user prompts while
     maintaining context.
   - Retrieval-Augmented Generation (RAG): Enhance retrieval capabilities.
   - Additional advanced features.

 This release focuses on stability and providing minimal features to help you
 get started with generative AI.

 * Getting Started:
   1. Download your preferred model and place it on your hard drive
     (e.g., `C:/LLM/GGUF`).
   2. Pass the full path of the model to the `LoadModel` method.
   3. Set `AMaxThreads` to the number of threads you wish to use (limited to
      the number of cores on your device).
   4. Pass your question to `SimpleInference` and wait for a response.

 By default, pressing **ESC** cancels inference; this can be customized in the
 Cancel Callback. The `AMaxContext` parameter determines the maximum context
 length for the model. Many models support an **8K context** or higher. The
 model card on Hugging Face typically lists this information. Additionally,
 the Info Callback displays all the model's metadata, including context length
 and other details.
 
 * Custom Model Templates:
   Custom chat templates serve as predefined structures that format input and
   output data in a way that aligns with the requirements of specific language
   models. These templates dictate how roles (e.g., "user" and "assistant")
   and their respective messages are presented, ensuring that the model can
   correctly interpret the context and flow of the conversation. By
   encapsulating information in a standardized format, templates provide
   clarity and consistency, which are essential for models to generate
   accurate and contextually appropriate responses.

   For example, the `CHATML_TEMPLATE` leverages tags like `<|im_start|>` and
   `<|im_end|>` to delineate each message explicitly, which is beneficial for
   multi-turn dialogues. The `GEMMA_TEMPLATE` adopts a minimalist approach,
   using simple tags like `<start_of_turn>` and `<end_of_turn>` to separate
   conversation turns, making it suitable for scenarios where concise
   formatting suffices. Meanwhile, the `PHI_TEMPLATE` incorporates explicit
   tags for roles and message boundaries, ensuring a high level of precision
   in parsing and generating conversational data.

   These templates are not rigid constructs but rather customizable tools that
   developers can adapt to their specific needs. Lumina allows you to define
   and pass in your custom chat formats, enabling seamless integration with
   various models, each of which might have unique formatting requirements.
   This flexibility is particularly valuable when working with different AI
   systems or when building applications with diverse conversational
   requirements, such as chatbots, customer support systems, or content
   generation tools. 
    
 ------------------------------------------------------------------------------

 >>> CHANGELOG <<<

 Version 0.1.0
 -------------
   - Initial release.    
 
===============================================================================}

unit Lumina;

{$IF CompilerVersion >= 36.0}
  // Code specific to Delphi Athens (12.2) and above
{$ELSE}
  {$MESSAGE ERROR 'This code requires  Delphi Athens (12.2) or later'}
{$IFEND}

{$IFNDEF WIN64}
  // Generates a compile-time error if the target platform is not Win64
  {$MESSAGE Error 'Unsupported platform'}
{$ENDIF}

{$Z4}  // Sets the enumeration size to 4 bytes
{$A8}  // Sets the alignment for record fields to 8 bytes

{$WARN SYMBOL_DEPRECATED OFF}
{$WARN SYMBOL_PLATFORM OFF}

{$WARN UNIT_PLATFORM OFF}
{$WARN UNIT_DEPRECATED OFF}

interface

{$REGION ' Uses '}
uses
  WinApi.Windows,
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.IOUtils,
  System.Math;
{$ENDREGION}

{$REGION ' Lumina.CLibs '}
const
  SQLITE_OMIT_LOAD_EXTENSION = 1;
  SQLITE_CORE = 1;
  SQLITE_ENABLE_COLUMN_METADATA = 1;
  GGML_FILE_MAGIC = $67676d6c;
  GGML_FILE_VERSION = 2;
  GGML_QNT_VERSION = 2;
  GGML_QNT_VERSION_FACTOR = 1000;
  GGML_MAX_DIMS = 4;
  GGML_MAX_PARAMS = 2048;
  GGML_MAX_SRC = 10;
  GGML_MAX_N_THREADS = 512;
  GGML_MAX_OP_PARAMS = 64;
  GGML_MAX_NAME = 64;
  GGML_DEFAULT_N_THREADS = 4;
  GGML_DEFAULT_GRAPH_SIZE = 2048;
  GGML_MEM_ALIGN = 16;
  GGML_EXIT_SUCCESS = 0;
  GGML_EXIT_ABORTED = 1;
  GGML_ROPE_TYPE_NEOX = 2;
  GGML_ROPE_TYPE_MROPE = 8;
  GGML_ROPE_TYPE_VISION = 24;
  GGUF_MAGIC = 'GGUF';
  GGUF_VERSION = 3;
  GGUF_DEFAULT_ALIGNMENT = 32;
  GGML_KQ_MASK_PAD = 32;
  GGML_N_TASKS_MAX = (-1);
  LLAMA_DEFAULT_SEED = $FFFFFFFF;
  LLAMA_TOKEN_NULL = -1;
  LLAMA_FILE_MAGIC_GGLA = $67676c61;
  LLAMA_FILE_MAGIC_GGSN = $6767736e;
  LLAMA_FILE_MAGIC_GGSQ = $67677371;
  LLAMA_SESSION_MAGIC = LLAMA_FILE_MAGIC_GGSN;
  LLAMA_SESSION_VERSION = 9;
  LLAMA_STATE_SEQ_MAGIC = LLAMA_FILE_MAGIC_GGSQ;
  LLAMA_STATE_SEQ_VERSION = 2;

type
  ggml_status = Integer;
  Pggml_status = ^ggml_status;

const
  GGML_STATUS_ALLOC_FAILED = -2;
  GGML_STATUS_FAILED = -1;
  GGML_STATUS_SUCCESS = 0;
  GGML_STATUS_ABORTED = 1;

type
  ggml_type = Integer;
  Pggml_type = ^ggml_type;

const
  GGML_TYPE_F32 = 0;
  GGML_TYPE_F16 = 1;
  GGML_TYPE_Q4_0 = 2;
  GGML_TYPE_Q4_1 = 3;
  GGML_TYPE_Q5_0 = 6;
  GGML_TYPE_Q5_1 = 7;
  GGML_TYPE_Q8_0 = 8;
  GGML_TYPE_Q8_1 = 9;
  GGML_TYPE_Q2_K = 10;
  GGML_TYPE_Q3_K = 11;
  GGML_TYPE_Q4_K = 12;
  GGML_TYPE_Q5_K = 13;
  GGML_TYPE_Q6_K = 14;
  GGML_TYPE_Q8_K = 15;
  GGML_TYPE_IQ2_XXS = 16;
  GGML_TYPE_IQ2_XS = 17;
  GGML_TYPE_IQ3_XXS = 18;
  GGML_TYPE_IQ1_S = 19;
  GGML_TYPE_IQ4_NL = 20;
  GGML_TYPE_IQ3_S = 21;
  GGML_TYPE_IQ2_S = 22;
  GGML_TYPE_IQ4_XS = 23;
  GGML_TYPE_I8 = 24;
  GGML_TYPE_I16 = 25;
  GGML_TYPE_I32 = 26;
  GGML_TYPE_I64 = 27;
  GGML_TYPE_F64 = 28;
  GGML_TYPE_IQ1_M = 29;
  GGML_TYPE_BF16 = 30;
  GGML_TYPE_TQ1_0 = 34;
  GGML_TYPE_TQ2_0 = 35;
  GGML_TYPE_COUNT = 39;

type
  ggml_prec = Integer;
  Pggml_prec = ^ggml_prec;

const
  GGML_PREC_DEFAULT = 0;
  GGML_PREC_F32 = 1;

type
  ggml_backend_type = Integer;
  Pggml_backend_type = ^ggml_backend_type;

const
  GGML_BACKEND_TYPE_CPU = 0;
  GGML_BACKEND_TYPE_GPU = 10;
  GGML_BACKEND_TYPE_GPU_SPLIT = 20;

type
  ggml_ftype = Integer;
  Pggml_ftype = ^ggml_ftype;

const
  GGML_FTYPE_UNKNOWN = -1;
  GGML_FTYPE_ALL_F32 = 0;
  GGML_FTYPE_MOSTLY_F16 = 1;
  GGML_FTYPE_MOSTLY_Q4_0 = 2;
  GGML_FTYPE_MOSTLY_Q4_1 = 3;
  GGML_FTYPE_MOSTLY_Q4_1_SOME_F16 = 4;
  GGML_FTYPE_MOSTLY_Q8_0 = 7;
  GGML_FTYPE_MOSTLY_Q5_0 = 8;
  GGML_FTYPE_MOSTLY_Q5_1 = 9;
  GGML_FTYPE_MOSTLY_Q2_K = 10;
  GGML_FTYPE_MOSTLY_Q3_K = 11;
  GGML_FTYPE_MOSTLY_Q4_K = 12;
  GGML_FTYPE_MOSTLY_Q5_K = 13;
  GGML_FTYPE_MOSTLY_Q6_K = 14;
  GGML_FTYPE_MOSTLY_IQ2_XXS = 15;
  GGML_FTYPE_MOSTLY_IQ2_XS = 16;
  GGML_FTYPE_MOSTLY_IQ3_XXS = 17;
  GGML_FTYPE_MOSTLY_IQ1_S = 18;
  GGML_FTYPE_MOSTLY_IQ4_NL = 19;
  GGML_FTYPE_MOSTLY_IQ3_S = 20;
  GGML_FTYPE_MOSTLY_IQ2_S = 21;
  GGML_FTYPE_MOSTLY_IQ4_XS = 22;
  GGML_FTYPE_MOSTLY_IQ1_M = 23;
  GGML_FTYPE_MOSTLY_BF16 = 24;

type
  ggml_op = Integer;
  Pggml_op = ^ggml_op;

const
  GGML_OP_NONE = 0;
  GGML_OP_DUP = 1;
  GGML_OP_ADD = 2;
  GGML_OP_ADD1 = 3;
  GGML_OP_ACC = 4;
  GGML_OP_SUB = 5;
  GGML_OP_MUL = 6;
  GGML_OP_DIV = 7;
  GGML_OP_SQR = 8;
  GGML_OP_SQRT = 9;
  GGML_OP_LOG = 10;
  GGML_OP_SIN = 11;
  GGML_OP_COS = 12;
  GGML_OP_SUM = 13;
  GGML_OP_SUM_ROWS = 14;
  GGML_OP_MEAN = 15;
  GGML_OP_ARGMAX = 16;
  GGML_OP_COUNT_EQUAL = 17;
  GGML_OP_REPEAT = 18;
  GGML_OP_REPEAT_BACK = 19;
  GGML_OP_CONCAT = 20;
  GGML_OP_SILU_BACK = 21;
  GGML_OP_NORM = 22;
  GGML_OP_RMS_NORM = 23;
  GGML_OP_RMS_NORM_BACK = 24;
  GGML_OP_GROUP_NORM = 25;
  GGML_OP_MUL_MAT = 26;
  GGML_OP_MUL_MAT_ID = 27;
  GGML_OP_OUT_PROD = 28;
  GGML_OP_SCALE = 29;
  GGML_OP_SET = 30;
  GGML_OP_CPY = 31;
  GGML_OP_CONT = 32;
  GGML_OP_RESHAPE = 33;
  GGML_OP_VIEW = 34;
  GGML_OP_PERMUTE = 35;
  GGML_OP_TRANSPOSE = 36;
  GGML_OP_GET_ROWS = 37;
  GGML_OP_GET_ROWS_BACK = 38;
  GGML_OP_DIAG = 39;
  GGML_OP_DIAG_MASK_INF = 40;
  GGML_OP_DIAG_MASK_ZERO = 41;
  GGML_OP_SOFT_MAX = 42;
  GGML_OP_SOFT_MAX_BACK = 43;
  GGML_OP_ROPE = 44;
  GGML_OP_ROPE_BACK = 45;
  GGML_OP_CLAMP = 46;
  GGML_OP_CONV_TRANSPOSE_1D = 47;
  GGML_OP_IM2COL = 48;
  GGML_OP_IM2COL_BACK = 49;
  GGML_OP_CONV_TRANSPOSE_2D = 50;
  GGML_OP_POOL_1D = 51;
  GGML_OP_POOL_2D = 52;
  GGML_OP_POOL_2D_BACK = 53;
  GGML_OP_UPSCALE = 54;
  GGML_OP_PAD = 55;
  GGML_OP_PAD_REFLECT_1D = 56;
  GGML_OP_ARANGE = 57;
  GGML_OP_TIMESTEP_EMBEDDING = 58;
  GGML_OP_ARGSORT = 59;
  GGML_OP_LEAKY_RELU = 60;
  GGML_OP_FLASH_ATTN_EXT = 61;
  GGML_OP_FLASH_ATTN_BACK = 62;
  GGML_OP_SSM_CONV = 63;
  GGML_OP_SSM_SCAN = 64;
  GGML_OP_WIN_PART = 65;
  GGML_OP_WIN_UNPART = 66;
  GGML_OP_GET_REL_POS = 67;
  GGML_OP_ADD_REL_POS = 68;
  GGML_OP_RWKV_WKV6 = 69;
  GGML_OP_UNARY = 70;
  GGML_OP_MAP_UNARY = 71;
  GGML_OP_MAP_BINARY = 72;
  GGML_OP_MAP_CUSTOM1_F32 = 73;
  GGML_OP_MAP_CUSTOM2_F32 = 74;
  GGML_OP_MAP_CUSTOM3_F32 = 75;
  GGML_OP_MAP_CUSTOM1 = 76;
  GGML_OP_MAP_CUSTOM2 = 77;
  GGML_OP_MAP_CUSTOM3 = 78;
  GGML_OP_CROSS_ENTROPY_LOSS = 79;
  GGML_OP_CROSS_ENTROPY_LOSS_BACK = 80;
  GGML_OP_OPT_STEP_ADAMW = 81;
  GGML_OP_COUNT = 82;

type
  ggml_unary_op = Integer;
  Pggml_unary_op = ^ggml_unary_op;

const
  GGML_UNARY_OP_ABS = 0;
  GGML_UNARY_OP_SGN = 1;
  GGML_UNARY_OP_NEG = 2;
  GGML_UNARY_OP_STEP = 3;
  GGML_UNARY_OP_TANH = 4;
  GGML_UNARY_OP_ELU = 5;
  GGML_UNARY_OP_RELU = 6;
  GGML_UNARY_OP_SIGMOID = 7;
  GGML_UNARY_OP_GELU = 8;
  GGML_UNARY_OP_GELU_QUICK = 9;
  GGML_UNARY_OP_SILU = 10;
  GGML_UNARY_OP_HARDSWISH = 11;
  GGML_UNARY_OP_HARDSIGMOID = 12;
  GGML_UNARY_OP_EXP = 13;
  GGML_UNARY_OP_COUNT = 14;

type
  ggml_object_type = Integer;
  Pggml_object_type = ^ggml_object_type;

const
  GGML_OBJECT_TYPE_TENSOR = 0;
  GGML_OBJECT_TYPE_GRAPH = 1;
  GGML_OBJECT_TYPE_WORK_BUFFER = 2;

type
  ggml_log_level = Integer;
  Pggml_log_level = ^ggml_log_level;

const
  GGML_LOG_LEVEL_NONE = 0;
  GGML_LOG_LEVEL_DEBUG = 1;
  GGML_LOG_LEVEL_INFO = 2;
  GGML_LOG_LEVEL_WARN = 3;
  GGML_LOG_LEVEL_ERROR = 4;
  GGML_LOG_LEVEL_CONT = 5;

type
  ggml_tensor_flag = Integer;
  Pggml_tensor_flag = ^ggml_tensor_flag;

const
  GGML_TENSOR_FLAG_INPUT = 1;
  GGML_TENSOR_FLAG_OUTPUT = 2;
  GGML_TENSOR_FLAG_PARAM = 4;
  GGML_TENSOR_FLAG_LOSS = 8;

type
  ggml_op_pool = Integer;
  Pggml_op_pool = ^ggml_op_pool;

const
  GGML_OP_POOL_MAX = 0;
  GGML_OP_POOL_AVG = 1;
  GGML_OP_POOL_COUNT = 2;

type
  ggml_sort_order = Integer;
  Pggml_sort_order = ^ggml_sort_order;

const
  GGML_SORT_ORDER_ASC = 0;
  GGML_SORT_ORDER_DESC = 1;

type
  gguf_type = Integer;
  Pgguf_type = ^gguf_type;

const
  GGUF_TYPE_UINT8 = 0;
  GGUF_TYPE_INT8 = 1;
  GGUF_TYPE_UINT16 = 2;
  GGUF_TYPE_INT16 = 3;
  GGUF_TYPE_UINT32 = 4;
  GGUF_TYPE_INT32 = 5;
  GGUF_TYPE_FLOAT32 = 6;
  GGUF_TYPE_BOOL = 7;
  GGUF_TYPE_STRING = 8;
  GGUF_TYPE_ARRAY = 9;
  GGUF_TYPE_UINT64 = 10;
  GGUF_TYPE_INT64 = 11;
  GGUF_TYPE_FLOAT64 = 12;
  GGUF_TYPE_COUNT = 13;

type
  ggml_sched_priority = Integer;
  Pggml_sched_priority = ^ggml_sched_priority;

const
  GGML_SCHED_PRIO_NORMAL = 0;
  GGML_SCHED_PRIO_MEDIUM = 1;
  GGML_SCHED_PRIO_HIGH = 2;
  GGML_SCHED_PRIO_REALTIME = 3;

type
  ggml_backend_buffer_usage = Integer;
  Pggml_backend_buffer_usage = ^ggml_backend_buffer_usage;

const
  GGML_BACKEND_BUFFER_USAGE_ANY = 0;
  GGML_BACKEND_BUFFER_USAGE_WEIGHTS = 1;
  GGML_BACKEND_BUFFER_USAGE_COMPUTE = 2;

type
  ggml_backend_dev_type = Integer;
  Pggml_backend_dev_type = ^ggml_backend_dev_type;

const
  GGML_BACKEND_DEVICE_TYPE_CPU = 0;
  GGML_BACKEND_DEVICE_TYPE_GPU = 1;
  GGML_BACKEND_DEVICE_TYPE_ACCEL = 2;

type
  ggml_numa_strategy = Integer;
  Pggml_numa_strategy = ^ggml_numa_strategy;

const
  GGML_NUMA_STRATEGY_DISABLED = 0;
  GGML_NUMA_STRATEGY_DISTRIBUTE = 1;
  GGML_NUMA_STRATEGY_ISOLATE = 2;
  GGML_NUMA_STRATEGY_NUMACTL = 3;
  GGML_NUMA_STRATEGY_MIRROR = 4;
  GGML_NUMA_STRATEGY_COUNT = 5;

type
  llama_vocab_type = Integer;
  Pllama_vocab_type = ^llama_vocab_type;

const
  LLAMA_VOCAB_TYPE_NONE = 0;
  LLAMA_VOCAB_TYPE_SPM = 1;
  LLAMA_VOCAB_TYPE_BPE = 2;
  LLAMA_VOCAB_TYPE_WPM = 3;
  LLAMA_VOCAB_TYPE_UGM = 4;
  LLAMA_VOCAB_TYPE_RWKV = 5;

type
  llama_vocab_pre_type = Integer;
  Pllama_vocab_pre_type = ^llama_vocab_pre_type;

const
  LLAMA_VOCAB_PRE_TYPE_DEFAULT = 0;
  LLAMA_VOCAB_PRE_TYPE_LLAMA3 = 1;
  LLAMA_VOCAB_PRE_TYPE_DEEPSEEK_LLM = 2;
  LLAMA_VOCAB_PRE_TYPE_DEEPSEEK_CODER = 3;
  LLAMA_VOCAB_PRE_TYPE_FALCON = 4;
  LLAMA_VOCAB_PRE_TYPE_MPT = 5;
  LLAMA_VOCAB_PRE_TYPE_STARCODER = 6;
  LLAMA_VOCAB_PRE_TYPE_GPT2 = 7;
  LLAMA_VOCAB_PRE_TYPE_REFACT = 8;
  LLAMA_VOCAB_PRE_TYPE_COMMAND_R = 9;
  LLAMA_VOCAB_PRE_TYPE_STABLELM2 = 10;
  LLAMA_VOCAB_PRE_TYPE_QWEN2 = 11;
  LLAMA_VOCAB_PRE_TYPE_OLMO = 12;
  LLAMA_VOCAB_PRE_TYPE_DBRX = 13;
  LLAMA_VOCAB_PRE_TYPE_SMAUG = 14;
  LLAMA_VOCAB_PRE_TYPE_PORO = 15;
  LLAMA_VOCAB_PRE_TYPE_CHATGLM3 = 16;
  LLAMA_VOCAB_PRE_TYPE_CHATGLM4 = 17;
  LLAMA_VOCAB_PRE_TYPE_VIKING = 18;
  LLAMA_VOCAB_PRE_TYPE_JAIS = 19;
  LLAMA_VOCAB_PRE_TYPE_TEKKEN = 20;
  LLAMA_VOCAB_PRE_TYPE_SMOLLM = 21;
  LLAMA_VOCAB_PRE_TYPE_CODESHELL = 22;
  LLAMA_VOCAB_PRE_TYPE_BLOOM = 23;
  LLAMA_VOCAB_PRE_TYPE_GPT3_FINNISH = 24;
  LLAMA_VOCAB_PRE_TYPE_EXAONE = 25;
  LLAMA_VOCAB_PRE_TYPE_CHAMELEON = 26;
  LLAMA_VOCAB_PRE_TYPE_MINERVA = 27;

type
  llama_rope_type = Integer;
  Pllama_rope_type = ^llama_rope_type;

const
  LLAMA_ROPE_TYPE_NONE = -1;
  LLAMA_ROPE_TYPE_NORM = 0;
  LLAMA_ROPE_TYPE_NEOX = 2;
  LLAMA_ROPE_TYPE_MROPE = 8;
  LLAMA_ROPE_TYPE_VISION = 24;

type
  llama_token_type = Integer;
  Pllama_token_type = ^llama_token_type;

const
  LLAMA_TOKEN_TYPE_UNDEFINED = 0;
  LLAMA_TOKEN_TYPE_NORMAL = 1;
  LLAMA_TOKEN_TYPE_UNKNOWN = 2;
  LLAMA_TOKEN_TYPE_CONTROL = 3;
  LLAMA_TOKEN_TYPE_USER_DEFINED = 4;
  LLAMA_TOKEN_TYPE_UNUSED = 5;
  LLAMA_TOKEN_TYPE_BYTE = 6;

type
  llama_token_attr = Integer;
  Pllama_token_attr = ^llama_token_attr;

const
  LLAMA_TOKEN_ATTR_UNDEFINED = 0;
  LLAMA_TOKEN_ATTR_UNKNOWN = 1;
  LLAMA_TOKEN_ATTR_UNUSED = 2;
  LLAMA_TOKEN_ATTR_NORMAL = 4;
  LLAMA_TOKEN_ATTR_CONTROL = 8;
  LLAMA_TOKEN_ATTR_USER_DEFINED = 16;
  LLAMA_TOKEN_ATTR_BYTE = 32;
  LLAMA_TOKEN_ATTR_NORMALIZED = 64;
  LLAMA_TOKEN_ATTR_LSTRIP = 128;
  LLAMA_TOKEN_ATTR_RSTRIP = 256;
  LLAMA_TOKEN_ATTR_SINGLE_WORD = 512;

type
  llama_ftype = Integer;
  Pllama_ftype = ^llama_ftype;

const
  LLAMA_FTYPE_ALL_F32 = 0;
  LLAMA_FTYPE_MOSTLY_F16 = 1;
  LLAMA_FTYPE_MOSTLY_Q4_0 = 2;
  LLAMA_FTYPE_MOSTLY_Q4_1 = 3;
  LLAMA_FTYPE_MOSTLY_Q8_0 = 7;
  LLAMA_FTYPE_MOSTLY_Q5_0 = 8;
  LLAMA_FTYPE_MOSTLY_Q5_1 = 9;
  LLAMA_FTYPE_MOSTLY_Q2_K = 10;
  LLAMA_FTYPE_MOSTLY_Q3_K_S = 11;
  LLAMA_FTYPE_MOSTLY_Q3_K_M = 12;
  LLAMA_FTYPE_MOSTLY_Q3_K_L = 13;
  LLAMA_FTYPE_MOSTLY_Q4_K_S = 14;
  LLAMA_FTYPE_MOSTLY_Q4_K_M = 15;
  LLAMA_FTYPE_MOSTLY_Q5_K_S = 16;
  LLAMA_FTYPE_MOSTLY_Q5_K_M = 17;
  LLAMA_FTYPE_MOSTLY_Q6_K = 18;
  LLAMA_FTYPE_MOSTLY_IQ2_XXS = 19;
  LLAMA_FTYPE_MOSTLY_IQ2_XS = 20;
  LLAMA_FTYPE_MOSTLY_Q2_K_S = 21;
  LLAMA_FTYPE_MOSTLY_IQ3_XS = 22;
  LLAMA_FTYPE_MOSTLY_IQ3_XXS = 23;
  LLAMA_FTYPE_MOSTLY_IQ1_S = 24;
  LLAMA_FTYPE_MOSTLY_IQ4_NL = 25;
  LLAMA_FTYPE_MOSTLY_IQ3_S = 26;
  LLAMA_FTYPE_MOSTLY_IQ3_M = 27;
  LLAMA_FTYPE_MOSTLY_IQ2_S = 28;
  LLAMA_FTYPE_MOSTLY_IQ2_M = 29;
  LLAMA_FTYPE_MOSTLY_IQ4_XS = 30;
  LLAMA_FTYPE_MOSTLY_IQ1_M = 31;
  LLAMA_FTYPE_MOSTLY_BF16 = 32;
  LLAMA_FTYPE_MOSTLY_TQ1_0 = 36;
  LLAMA_FTYPE_MOSTLY_TQ2_0 = 37;
  LLAMA_FTYPE_GUESSED = 1024;

type
  llama_rope_scaling_type = Integer;
  Pllama_rope_scaling_type = ^llama_rope_scaling_type;

const
  LLAMA_ROPE_SCALING_TYPE_UNSPECIFIED = -1;
  LLAMA_ROPE_SCALING_TYPE_NONE = 0;
  LLAMA_ROPE_SCALING_TYPE_LINEAR = 1;
  LLAMA_ROPE_SCALING_TYPE_YARN = 2;
  LLAMA_ROPE_SCALING_TYPE_LONGROPE = 3;
  LLAMA_ROPE_SCALING_TYPE_MAX_VALUE = 3;

type
  llama_pooling_type = Integer;
  Pllama_pooling_type = ^llama_pooling_type;

const
  LLAMA_POOLING_TYPE_UNSPECIFIED = -1;
  LLAMA_POOLING_TYPE_NONE = 0;
  LLAMA_POOLING_TYPE_MEAN = 1;
  LLAMA_POOLING_TYPE_CLS = 2;
  LLAMA_POOLING_TYPE_LAST = 3;
  LLAMA_POOLING_TYPE_RANK = 4;

type
  llama_attention_type = Integer;
  Pllama_attention_type = ^llama_attention_type;

const
  LLAMA_ATTENTION_TYPE_UNSPECIFIED = -1;
  LLAMA_ATTENTION_TYPE_CAUSAL = 0;
  LLAMA_ATTENTION_TYPE_NON_CAUSAL = 1;

type
  llama_split_mode = Integer;
  Pllama_split_mode = ^llama_split_mode;

const
  LLAMA_SPLIT_MODE_NONE = 0;
  LLAMA_SPLIT_MODE_LAYER = 1;
  LLAMA_SPLIT_MODE_ROW = 2;

type
  llama_model_kv_override_type = Integer;
  Pllama_model_kv_override_type = ^llama_model_kv_override_type;

const
  LLAMA_KV_OVERRIDE_TYPE_INT = 0;
  LLAMA_KV_OVERRIDE_TYPE_FLOAT = 1;
  LLAMA_KV_OVERRIDE_TYPE_BOOL = 2;
  LLAMA_KV_OVERRIDE_TYPE_STR = 3;

type
  // Forward declarations
  PPUTF8Char = ^PUTF8Char;
  PInt8 = ^Int8;
  PInt32 = ^Int32;
  PNativeUInt = ^NativeUInt;
  PUInt8 = ^UInt8;
  PInt64 = ^Int64;
  PPointer = ^Pointer;
  Pggml_object = Pointer;
  PPggml_object = ^Pggml_object;
  Pggml_context = Pointer;
  PPggml_context = ^Pggml_context;
  Pggml_cgraph = Pointer;
  PPggml_cgraph = ^Pggml_cgraph;
  Pggml_backend_buffer = Pointer;
  PPggml_backend_buffer = ^Pggml_backend_buffer;
  Pgguf_context = Pointer;
  PPgguf_context = ^Pgguf_context;
  Pggml_threadpool = Pointer;
  PPggml_threadpool = ^Pggml_threadpool;
  Pggml_backend_buffer_type = Pointer;
  PPggml_backend_buffer_type = ^Pggml_backend_buffer_type;
  Pggml_backend = Pointer;
  PPggml_backend = ^Pggml_backend;
  Pggml_gallocr = Pointer;
  PPggml_gallocr = ^Pggml_gallocr;
  Pggml_backend_event = Pointer;
  PPggml_backend_event = ^Pggml_backend_event;
  Pggml_backend_reg = Pointer;
  PPggml_backend_reg = ^Pggml_backend_reg;
  Pggml_backend_device = Pointer;
  PPggml_backend_device = ^Pggml_backend_device;
  Pggml_backend_sched = Pointer;
  PPggml_backend_sched = ^Pggml_backend_sched;
  Pllama_model = Pointer;
  PPllama_model = ^Pllama_model;
  Pllama_context = Pointer;
  PPllama_context = ^Pllama_context;
  Pllama_lora_adapter = Pointer;
  PPllama_lora_adapter = ^Pllama_lora_adapter;
  Pggml_bf16_t = ^ggml_bf16_t;
  Pggml_init_params = ^ggml_init_params;
  Pggml_tensor = ^ggml_tensor;
  PPggml_tensor = ^Pggml_tensor;
  Pgguf_init_params = ^gguf_init_params;
  Pggml_type_traits = ^ggml_type_traits;
  Pggml_threadpool_params = ^ggml_threadpool_params;
  Pggml_tallocr = ^ggml_tallocr;
  Pggml_backend_dev_caps = ^ggml_backend_dev_caps;
  Pggml_backend_dev_props = ^ggml_backend_dev_props;
  Pggml_backend_feature = ^ggml_backend_feature;
  Pggml_backend_graph_copy = ^ggml_backend_graph_copy;
  Pggml_cplan = ^ggml_cplan;
  Pggml_type_traits_cpu = ^ggml_type_traits_cpu;
  Pllama_token_data = ^llama_token_data;
  Pllama_token_data_array = ^llama_token_data_array;
  Pllama_batch = ^llama_batch;
  Pllama_model_kv_override = ^llama_model_kv_override;
  Pllama_model_params = ^llama_model_params;
  Pllama_context_params = ^llama_context_params;
  Pllama_model_quantize_params = ^llama_model_quantize_params;
  Pllama_logit_bias = ^llama_logit_bias;
  Pllama_sampler_chain_params = ^llama_sampler_chain_params;
  Pllama_chat_message = ^llama_chat_message;
  Pllama_kv_cache_view_cell = ^llama_kv_cache_view_cell;
  Pllama_kv_cache_view = ^llama_kv_cache_view;
  Pllama_sampler_i = ^llama_sampler_i;
  Pllama_sampler = ^llama_sampler;
  Pllama_perf_context_data = ^llama_perf_context_data;
  Pllama_perf_sampler_data = ^llama_perf_sampler_data;

  ggml_fp16_t = UInt16;
  Pggml_fp16_t = ^ggml_fp16_t;

  ggml_bf16_t = record
    bits: UInt16;
  end;

  ggml_init_params = record
    mem_size: NativeUInt;
    mem_buffer: Pointer;
    no_alloc: Boolean;
  end;

  ggml_tensor = record
    &type: ggml_type;
    backend: ggml_backend_type;
    buffer: Pggml_backend_buffer;
    ne: array [0..3] of Int64;
    nb: array [0..3] of NativeUInt;
    op: ggml_op;
    op_params: array [0..15] of Int32;
    flags: Int32;
    src: array [0..9] of Pggml_tensor;
    view_src: Pggml_tensor;
    view_offs: NativeUInt;
    data: Pointer;
    name: array [0..63] of UTF8Char;
    extra: Pointer;
    padding: array [0..7] of UTF8Char;
  end;

  ggml_abort_callback = function(data: Pointer): Boolean; cdecl;
  ggml_guid = array [0..15] of UInt8;
  ggml_guid_t = ^ggml_guid;

  ggml_unary_op_f32_t = procedure(const p1: Integer; p2: PSingle; const p3: PSingle); cdecl;

  ggml_binary_op_f32_t = procedure(const p1: Integer; p2: PSingle; const p3: PSingle; const p4: PSingle); cdecl;

  ggml_custom1_op_f32_t = procedure(p1: Pggml_tensor; const p2: Pggml_tensor); cdecl;

  ggml_custom2_op_f32_t = procedure(p1: Pggml_tensor; const p2: Pggml_tensor; const p3: Pggml_tensor); cdecl;

  ggml_custom3_op_f32_t = procedure(p1: Pggml_tensor; const p2: Pggml_tensor; const p3: Pggml_tensor; const p4: Pggml_tensor); cdecl;

  ggml_custom1_op_t = procedure(dst: Pggml_tensor; const a: Pggml_tensor; ith: Integer; nth: Integer; userdata: Pointer); cdecl;

  ggml_custom2_op_t = procedure(dst: Pggml_tensor; const a: Pggml_tensor; const b: Pggml_tensor; ith: Integer; nth: Integer; userdata: Pointer); cdecl;

  ggml_custom3_op_t = procedure(dst: Pggml_tensor; const a: Pggml_tensor; const b: Pggml_tensor; const c: Pggml_tensor; ith: Integer; nth: Integer; userdata: Pointer); cdecl;

  ggml_log_callback = procedure(level: ggml_log_level; const text: PUTF8Char; user_data: Pointer); cdecl;

  gguf_init_params = record
    no_alloc: Boolean;
    ctx: PPggml_context;
  end;

  ggml_to_float_t = procedure(const x: Pointer; y: PSingle; k: Int64); cdecl;

  ggml_from_float_t = procedure(const x: PSingle; y: Pointer; k: Int64); cdecl;

  ggml_type_traits = record
    type_name: PUTF8Char;
    blck_size: Int64;
    blck_size_interleave: Int64;
    type_size: NativeUInt;
    is_quantized: Boolean;
    to_float: ggml_to_float_t;
    from_float_ref: ggml_from_float_t;
  end;

  ggml_threadpool_params = record
    cpumask: array [0..511] of Boolean;
    n_threads: Integer;
    prio: ggml_sched_priority;
    poll: UInt32;
    strict_cpu: Boolean;
    paused: Boolean;
  end;

  ggml_threadpool_t = Pointer;
  Pggml_threadpool_t = ^ggml_threadpool_t;
  ggml_backend_buffer_type_t = Pointer;
  Pggml_backend_buffer_type_t = ^ggml_backend_buffer_type_t;
  ggml_backend_buffer_t = Pointer;
  Pggml_backend_buffer_t = ^ggml_backend_buffer_t;
  ggml_backend_t = Pointer;
  Pggml_backend_t = ^ggml_backend_t;

  ggml_tallocr = record
    buffer: ggml_backend_buffer_t;
    base: Pointer;
    alignment: NativeUInt;
    offset: NativeUInt;
  end;

  ggml_gallocr_t = Pointer;
  Pggml_gallocr_t = ^ggml_gallocr_t;
  ggml_backend_event_t = Pointer;
  Pggml_backend_event_t = ^ggml_backend_event_t;
  ggml_backend_graph_plan_t = Pointer;
  ggml_backend_reg_t = Pointer;
  Pggml_backend_reg_t = ^ggml_backend_reg_t;
  ggml_backend_dev_t = Pointer;
  Pggml_backend_dev_t = ^ggml_backend_dev_t;

  ggml_backend_dev_caps = record
    async: Boolean;
    host_buffer: Boolean;
    buffer_from_host_ptr: Boolean;
    events: Boolean;
  end;

  ggml_backend_dev_props = record
    name: PUTF8Char;
    description: PUTF8Char;
    memory_free: NativeUInt;
    memory_total: NativeUInt;
    &type: ggml_backend_dev_type;
    caps: ggml_backend_dev_caps;
  end;

  ggml_backend_split_buffer_type_t = function(main_device: Integer; const tensor_split: PSingle): ggml_backend_buffer_type_t; cdecl;

  ggml_backend_set_n_threads_t = procedure(backend: ggml_backend_t; n_threads: Integer); cdecl;

  ggml_backend_dev_get_extra_bufts_t = function(device: ggml_backend_dev_t): Pggml_backend_buffer_type_t; cdecl;

  ggml_backend_set_abort_callback_t = procedure(backend: ggml_backend_t; abort_callback: ggml_abort_callback; abort_callback_data: Pointer); cdecl;

  ggml_backend_feature = record
    name: PUTF8Char;
    value: PUTF8Char;
  end;

  ggml_backend_get_features_t = function(reg: ggml_backend_reg_t): Pggml_backend_feature; cdecl;
  ggml_backend_sched_t = Pointer;
  Pggml_backend_sched_t = ^ggml_backend_sched_t;

  ggml_backend_sched_eval_callback = function(t: Pggml_tensor; ask: Boolean; user_data: Pointer): Boolean; cdecl;

  ggml_backend_graph_copy = record
    buffer: ggml_backend_buffer_t;
    ctx_allocated: Pggml_context;
    ctx_unallocated: Pggml_context;
    graph: Pggml_cgraph;
  end;

  ggml_backend_eval_callback = function(node_index: Integer; t1: Pggml_tensor; t2: Pggml_tensor; user_data: Pointer): Boolean; cdecl;

  ggml_cplan = record
    work_size: NativeUInt;
    work_data: PUInt8;
    n_threads: Integer;
    threadpool: Pggml_threadpool;
    abort_callback: ggml_abort_callback;
    abort_callback_data: Pointer;
  end;

  ggml_vec_dot_t = procedure(n: Integer; s: PSingle; bs: NativeUInt; const x: Pointer; bx: NativeUInt; const y: Pointer; by: NativeUInt; nrc: Integer); cdecl;

  ggml_type_traits_cpu = record
    from_float: ggml_from_float_t;
    vec_dot: ggml_vec_dot_t;
    vec_dot_type: ggml_type;
    nrows: Int64;
  end;

  llama_pos = Int32;
  Pllama_pos = ^llama_pos;
  llama_token = Int32;
  Pllama_token = ^llama_token;
  llama_seq_id = Int32;
  Pllama_seq_id = ^llama_seq_id;
  PPllama_seq_id = ^Pllama_seq_id;

  llama_token_data = record
    id: llama_token;
    logit: Single;
    p: Single;
  end;

  llama_token_data_array = record
    data: Pllama_token_data;
    size: NativeUInt;
    selected: Int64;
    sorted: Boolean;
  end;

  llama_progress_callback = function(progress: Single; user_data: Pointer): Boolean; cdecl;

  llama_batch = record
    n_tokens: Int32;
    token: Pllama_token;
    embd: PSingle;
    pos: Pllama_pos;
    n_seq_id: PInt32;
    seq_id: PPllama_seq_id;
    logits: PInt8;
  end;

  P_anonymous_type_1 = ^_anonymous_type_1;
  _anonymous_type_1 = record
    case Integer of
      0: (val_i64: Int64);
      1: (val_f64: Double);
      2: (val_bool: Boolean);
      3: (val_str: array [0..127] of UTF8Char);
  end;

  llama_model_kv_override = record
    tag: llama_model_kv_override_type;
    key: array [0..127] of UTF8Char;
    f3: _anonymous_type_1;
  end;

  llama_model_params = record
    devices: Pggml_backend_dev_t;
    n_gpu_layers: Int32;
    split_mode: llama_split_mode;
    main_gpu: Int32;
    tensor_split: PSingle;
    rpc_servers: PUTF8Char;
    progress_callback: llama_progress_callback;
    progress_callback_user_data: Pointer;
    kv_overrides: Pllama_model_kv_override;
    vocab_only: Boolean;
    use_mmap: Boolean;
    use_mlock: Boolean;
    check_tensors: Boolean;
  end;

  llama_context_params = record
    n_ctx: UInt32;
    n_batch: UInt32;
    n_ubatch: UInt32;
    n_seq_max: UInt32;
    n_threads: Int32;
    n_threads_batch: Int32;
    rope_scaling_type: llama_rope_scaling_type;
    pooling_type: llama_pooling_type;
    attention_type: llama_attention_type;
    rope_freq_base: Single;
    rope_freq_scale: Single;
    yarn_ext_factor: Single;
    yarn_attn_factor: Single;
    yarn_beta_fast: Single;
    yarn_beta_slow: Single;
    yarn_orig_ctx: UInt32;
    defrag_thold: Single;
    cb_eval: ggml_backend_sched_eval_callback;
    cb_eval_user_data: Pointer;
    type_k: ggml_type;
    type_v: ggml_type;
    logits_all: Boolean;
    embeddings: Boolean;
    offload_kqv: Boolean;
    flash_attn: Boolean;
    no_perf: Boolean;
    abort_callback: ggml_abort_callback;
    abort_callback_data: Pointer;
  end;

  llama_model_quantize_params = record
    nthread: Int32;
    ftype: llama_ftype;
    output_tensor_type: ggml_type;
    token_embedding_type: ggml_type;
    allow_requantize: Boolean;
    quantize_output_tensor: Boolean;
    only_copy: Boolean;
    pure: Boolean;
    keep_split: Boolean;
    imatrix: Pointer;
    kv_overrides: Pointer;
  end;

  llama_logit_bias = record
    token: llama_token;
    bias: Single;
  end;

  llama_sampler_chain_params = record
    no_perf: Boolean;
  end;

  llama_chat_message = record
    role: PUTF8Char;
    content: PUTF8Char;
  end;

  llama_kv_cache_view_cell = record
    pos: llama_pos;
  end;

  llama_kv_cache_view = record
    n_cells: Int32;
    n_seq_max: Int32;
    token_count: Int32;
    used_cells: Int32;
    max_contiguous: Int32;
    max_contiguous_idx: Int32;
    cells: Pllama_kv_cache_view_cell;
    cells_sequences: Pllama_seq_id;
  end;

  llama_sampler_context_t = Pointer;

  llama_sampler_i = record
    name: function(const smpl: Pllama_sampler): PUTF8Char; cdecl;
    accept: procedure(smpl: Pllama_sampler; token: llama_token); cdecl;
    apply: procedure(smpl: Pllama_sampler; cur_p: Pllama_token_data_array); cdecl;
    reset: procedure(smpl: Pllama_sampler); cdecl;
    clone: function(const smpl: Pllama_sampler): Pllama_sampler; cdecl;
    free: procedure(smpl: Pllama_sampler); cdecl;
  end;

  llama_sampler = record
    iface: Pllama_sampler_i;
    ctx: llama_sampler_context_t;
  end;

  llama_perf_context_data = record
    t_start_ms: Double;
    t_load_ms: Double;
    t_p_eval_ms: Double;
    t_eval_ms: Double;
    n_p_eval: Int32;
    n_eval: Int32;
  end;

  llama_perf_sampler_data = record
    t_sample_ms: Double;
    n_sample: Int32;
  end;

  cerr_callback = procedure(const text: PUTF8Char; user_data: Pointer); cdecl;

var
  ggml_abort: procedure(const &file: PUTF8Char; line: Integer; const fmt: PUTF8Char) varargs; cdecl;
  ggml_status_to_string: function(status: ggml_status): PUTF8Char; cdecl;
  ggml_fp16_to_fp32: function(p1: ggml_fp16_t): Single; cdecl;
  ggml_fp32_to_fp16: function(p1: Single): ggml_fp16_t; cdecl;
  ggml_fp16_to_fp32_row: procedure(const p1: Pggml_fp16_t; p2: PSingle; p3: Int64); cdecl;
  ggml_fp32_to_fp16_row: procedure(const p1: PSingle; p2: Pggml_fp16_t; p3: Int64); cdecl;
  ggml_fp32_to_bf16: function(p1: Single): ggml_bf16_t; cdecl;
  ggml_bf16_to_fp32: function(p1: ggml_bf16_t): Single; cdecl;
  ggml_bf16_to_fp32_row: procedure(const p1: Pggml_bf16_t; p2: PSingle; p3: Int64); cdecl;
  ggml_fp32_to_bf16_row_ref: procedure(const p1: PSingle; p2: Pggml_bf16_t; p3: Int64); cdecl;
  ggml_fp32_to_bf16_row: procedure(const p1: PSingle; p2: Pggml_bf16_t; p3: Int64); cdecl;
  ggml_guid_matches: function(guid_a: ggml_guid_t; guid_b: ggml_guid_t): Boolean; cdecl;
  ggml_time_init: procedure(); cdecl;
  ggml_time_ms: function(): Int64; cdecl;
  ggml_time_us: function(): Int64; cdecl;
  ggml_cycles: function(): Int64; cdecl;
  ggml_cycles_per_ms: function(): Int64; cdecl;
  ggml_fopen: function(const fname: PUTF8Char; const mode: PUTF8Char): PPointer; cdecl;
  ggml_print_object: procedure(const obj: Pggml_object); cdecl;
  ggml_print_objects: procedure(const ctx: Pggml_context); cdecl;
  ggml_nelements: function(const tensor: Pggml_tensor): Int64; cdecl;
  ggml_nrows: function(const tensor: Pggml_tensor): Int64; cdecl;
  ggml_nbytes: function(const tensor: Pggml_tensor): NativeUInt; cdecl;
  ggml_nbytes_pad: function(const tensor: Pggml_tensor): NativeUInt; cdecl;
  ggml_blck_size: function(&type: ggml_type): Int64; cdecl;
  ggml_type_size: function(&type: ggml_type): NativeUInt; cdecl;
  ggml_row_size: function(&type: ggml_type; ne: Int64): NativeUInt; cdecl;
  ggml_type_sizef: function(&type: ggml_type): Double; cdecl;
  ggml_type_name: function(&type: ggml_type): PUTF8Char; cdecl;
  ggml_op_name: function(op: ggml_op): PUTF8Char; cdecl;
  ggml_op_symbol: function(op: ggml_op): PUTF8Char; cdecl;
  ggml_unary_op_name: function(op: ggml_unary_op): PUTF8Char; cdecl;
  ggml_op_desc: function(const t: Pggml_tensor): PUTF8Char; cdecl;
  ggml_element_size: function(const tensor: Pggml_tensor): NativeUInt; cdecl;
  ggml_is_quantized: function(&type: ggml_type): Boolean; cdecl;
  ggml_ftype_to_ggml_type: function(ftype: ggml_ftype): ggml_type; cdecl;
  ggml_is_transposed: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_permuted: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_empty: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_scalar: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_vector: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_matrix: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_3d: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_n_dims: function(const tensor: Pggml_tensor): Integer; cdecl;
  ggml_is_contiguous: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_contiguous_0: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_contiguous_1: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_is_contiguous_2: function(const tensor: Pggml_tensor): Boolean; cdecl;
  ggml_are_same_shape: function(const t0: Pggml_tensor; const t1: Pggml_tensor): Boolean; cdecl;
  ggml_are_same_stride: function(const t0: Pggml_tensor; const t1: Pggml_tensor): Boolean; cdecl;
  ggml_can_repeat: function(const t0: Pggml_tensor; const t1: Pggml_tensor): Boolean; cdecl;
  ggml_tensor_overhead: function(): NativeUInt; cdecl;
  ggml_validate_row_data: function(&type: ggml_type; const data: Pointer; nbytes: NativeUInt): Boolean; cdecl;
  ggml_init: function(params: ggml_init_params): Pggml_context; cdecl;
  ggml_reset: procedure(ctx: Pggml_context); cdecl;
  ggml_free: procedure(ctx: Pggml_context); cdecl;
  ggml_used_mem: function(const ctx: Pggml_context): NativeUInt; cdecl;
  ggml_get_no_alloc: function(ctx: Pggml_context): Boolean; cdecl;
  ggml_set_no_alloc: procedure(ctx: Pggml_context; no_alloc: Boolean); cdecl;
  ggml_get_mem_buffer: function(const ctx: Pggml_context): Pointer; cdecl;
  ggml_get_mem_size: function(const ctx: Pggml_context): NativeUInt; cdecl;
  ggml_get_max_tensor_size: function(const ctx: Pggml_context): NativeUInt; cdecl;
  ggml_new_tensor: function(ctx: Pggml_context; &type: ggml_type; n_dims: Integer; const ne: PInt64): Pggml_tensor; cdecl;
  ggml_new_tensor_1d: function(ctx: Pggml_context; &type: ggml_type; ne0: Int64): Pggml_tensor; cdecl;
  ggml_new_tensor_2d: function(ctx: Pggml_context; &type: ggml_type; ne0: Int64; ne1: Int64): Pggml_tensor; cdecl;
  ggml_new_tensor_3d: function(ctx: Pggml_context; &type: ggml_type; ne0: Int64; ne1: Int64; ne2: Int64): Pggml_tensor; cdecl;
  ggml_new_tensor_4d: function(ctx: Pggml_context; &type: ggml_type; ne0: Int64; ne1: Int64; ne2: Int64; ne3: Int64): Pggml_tensor; cdecl;
  ggml_new_buffer: function(ctx: Pggml_context; nbytes: NativeUInt): Pointer; cdecl;
  ggml_dup_tensor: function(ctx: Pggml_context; const src: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_view_tensor: function(ctx: Pggml_context; src: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_get_first_tensor: function(const ctx: Pggml_context): Pggml_tensor; cdecl;
  ggml_get_next_tensor: function(const ctx: Pggml_context; tensor: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_get_tensor: function(ctx: Pggml_context; const name: PUTF8Char): Pggml_tensor; cdecl;
  ggml_unravel_index: procedure(const tensor: Pggml_tensor; i: Int64; i0: PInt64; i1: PInt64; i2: PInt64; i3: PInt64); cdecl;
  ggml_get_unary_op: function(const tensor: Pggml_tensor): ggml_unary_op; cdecl;
  ggml_get_data: function(const tensor: Pggml_tensor): Pointer; cdecl;
  ggml_get_data_f32: function(const tensor: Pggml_tensor): PSingle; cdecl;
  ggml_get_name: function(const tensor: Pggml_tensor): PUTF8Char; cdecl;
  ggml_set_name: function(tensor: Pggml_tensor; const name: PUTF8Char): Pggml_tensor; cdecl;
  ggml_format_name: function(tensor: Pggml_tensor; const fmt: PUTF8Char): Pggml_tensor varargs; cdecl;
  ggml_set_input: procedure(tensor: Pggml_tensor); cdecl;
  ggml_set_output: procedure(tensor: Pggml_tensor); cdecl;
  ggml_set_param: procedure(ctx: Pggml_context; tensor: Pggml_tensor); cdecl;
  ggml_set_loss: procedure(tensor: Pggml_tensor); cdecl;
  ggml_dup: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_dup_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_add: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_add_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_add_cast: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; &type: ggml_type): Pggml_tensor; cdecl;
  ggml_add1: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_add1_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_acc: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; nb2: NativeUInt; nb3: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_acc_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; nb2: NativeUInt; nb3: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_sub: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sub_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_mul: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_mul_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_div: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_div_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sqr: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sqr_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sqrt: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sqrt_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_log: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_log_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sin: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sin_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_cos: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_cos_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sum: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sum_rows: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_mean: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_argmax: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_count_equal: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_repeat: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_repeat_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_concat: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; dim: Integer): Pggml_tensor; cdecl;
  ggml_abs: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_abs_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sgn: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sgn_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_neg: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_neg_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_step: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_step_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_tanh: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_tanh_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_elu: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_elu_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_relu: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_leaky_relu: function(ctx: Pggml_context; a: Pggml_tensor; negative_slope: Single; inplace: Boolean): Pggml_tensor; cdecl;
  ggml_relu_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sigmoid: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_sigmoid_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_gelu: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_gelu_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_gelu_quick: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_gelu_quick_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_silu: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_silu_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_silu_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_hardswish: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_hardsigmoid: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_exp: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_exp_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_norm: function(ctx: Pggml_context; a: Pggml_tensor; eps: Single): Pggml_tensor; cdecl;
  ggml_norm_inplace: function(ctx: Pggml_context; a: Pggml_tensor; eps: Single): Pggml_tensor; cdecl;
  ggml_rms_norm: function(ctx: Pggml_context; a: Pggml_tensor; eps: Single): Pggml_tensor; cdecl;
  ggml_rms_norm_inplace: function(ctx: Pggml_context; a: Pggml_tensor; eps: Single): Pggml_tensor; cdecl;
  ggml_group_norm: function(ctx: Pggml_context; a: Pggml_tensor; n_groups: Integer; eps: Single): Pggml_tensor; cdecl;
  ggml_group_norm_inplace: function(ctx: Pggml_context; a: Pggml_tensor; n_groups: Integer; eps: Single): Pggml_tensor; cdecl;
  ggml_rms_norm_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; eps: Single): Pggml_tensor; cdecl;
  ggml_mul_mat: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_mul_mat_set_prec: procedure(a: Pggml_tensor; prec: ggml_prec); cdecl;
  ggml_mul_mat_id: function(ctx: Pggml_context; &as: Pggml_tensor; b: Pggml_tensor; ids: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_out_prod: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_scale: function(ctx: Pggml_context; a: Pggml_tensor; s: Single): Pggml_tensor; cdecl;
  ggml_scale_inplace: function(ctx: Pggml_context; a: Pggml_tensor; s: Single): Pggml_tensor; cdecl;
  ggml_set: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; nb2: NativeUInt; nb3: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_set_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; nb2: NativeUInt; nb3: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_set_1d: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_set_1d_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_set_2d: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_set_2d_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; nb1: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_cpy: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_cast: function(ctx: Pggml_context; a: Pggml_tensor; &type: ggml_type): Pggml_tensor; cdecl;
  ggml_cont: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_cont_1d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64): Pggml_tensor; cdecl;
  ggml_cont_2d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64): Pggml_tensor; cdecl;
  ggml_cont_3d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64): Pggml_tensor; cdecl;
  ggml_cont_4d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64; ne3: Int64): Pggml_tensor; cdecl;
  ggml_reshape: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_reshape_1d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64): Pggml_tensor; cdecl;
  ggml_reshape_2d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64): Pggml_tensor; cdecl;
  ggml_reshape_3d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64): Pggml_tensor; cdecl;
  ggml_reshape_4d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64; ne3: Int64): Pggml_tensor; cdecl;
  ggml_view_1d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_view_2d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; nb1: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_view_3d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64; nb1: NativeUInt; nb2: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_view_4d: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Int64; ne1: Int64; ne2: Int64; ne3: Int64; nb1: NativeUInt; nb2: NativeUInt; nb3: NativeUInt; offset: NativeUInt): Pggml_tensor; cdecl;
  ggml_permute: function(ctx: Pggml_context; a: Pggml_tensor; axis0: Integer; axis1: Integer; axis2: Integer; axis3: Integer): Pggml_tensor; cdecl;
  ggml_transpose: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_get_rows: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_get_rows_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_diag: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_diag_mask_inf: function(ctx: Pggml_context; a: Pggml_tensor; n_past: Integer): Pggml_tensor; cdecl;
  ggml_diag_mask_inf_inplace: function(ctx: Pggml_context; a: Pggml_tensor; n_past: Integer): Pggml_tensor; cdecl;
  ggml_diag_mask_zero: function(ctx: Pggml_context; a: Pggml_tensor; n_past: Integer): Pggml_tensor; cdecl;
  ggml_diag_mask_zero_inplace: function(ctx: Pggml_context; a: Pggml_tensor; n_past: Integer): Pggml_tensor; cdecl;
  ggml_soft_max: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_soft_max_inplace: function(ctx: Pggml_context; a: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_soft_max_ext: function(ctx: Pggml_context; a: Pggml_tensor; mask: Pggml_tensor; scale: Single; max_bias: Single): Pggml_tensor; cdecl;
  ggml_soft_max_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_soft_max_back_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_rope: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; n_dims: Integer; mode: Integer): Pggml_tensor; cdecl;
  ggml_rope_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; n_dims: Integer; mode: Integer): Pggml_tensor; cdecl;
  ggml_rope_ext: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; n_dims: Integer; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_rope_multi: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; n_dims: Integer; sections: PInteger; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_rope_ext_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; n_dims: Integer; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_rope_custom: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; n_dims: Integer; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_rope_custom_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; n_dims: Integer; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_rope_yarn_corr_dims: procedure(n_dims: Integer; n_ctx_orig: Integer; freq_base: Single; beta_fast: Single; beta_slow: Single; dims: PSingle); cdecl;
  ggml_rope_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; n_dims: Integer; mode: Integer; n_ctx_orig: Integer; freq_base: Single; freq_scale: Single; ext_factor: Single; attn_factor: Single; beta_fast: Single; beta_slow: Single): Pggml_tensor; cdecl;
  ggml_clamp: function(ctx: Pggml_context; a: Pggml_tensor; min: Single; max: Single): Pggml_tensor; cdecl;
  ggml_im2col: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; s1: Integer; p0: Integer; p1: Integer; d0: Integer; d1: Integer; is_2D: Boolean; dst_type: ggml_type): Pggml_tensor; cdecl;
  ggml_im2col_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; ne: PInt64; s0: Integer; s1: Integer; p0: Integer; p1: Integer; d0: Integer; d1: Integer; is_2D: Boolean): Pggml_tensor; cdecl;
  ggml_conv_1d: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; p0: Integer; d0: Integer): Pggml_tensor; cdecl;
  ggml_conv_1d_ph: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s: Integer; d: Integer): Pggml_tensor; cdecl;
  ggml_conv_1d_dw: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; p0: Integer; d0: Integer): Pggml_tensor; cdecl;
  ggml_conv_1d_dw_ph: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; d0: Integer): Pggml_tensor; cdecl;
  ggml_conv_transpose_1d: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; p0: Integer; d0: Integer): Pggml_tensor; cdecl;
  ggml_conv_2d: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; s1: Integer; p0: Integer; p1: Integer; d0: Integer; d1: Integer): Pggml_tensor; cdecl;
  ggml_conv_2d_sk_p0: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_conv_2d_s1_ph: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_conv_2d_dw: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; s0: Integer; s1: Integer; p0: Integer; p1: Integer; d0: Integer; d1: Integer): Pggml_tensor; cdecl;
  ggml_conv_transpose_2d_p0: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; stride: Integer): Pggml_tensor; cdecl;
  ggml_pool_1d: function(ctx: Pggml_context; a: Pggml_tensor; op: ggml_op_pool; k0: Integer; s0: Integer; p0: Integer): Pggml_tensor; cdecl;
  ggml_pool_2d: function(ctx: Pggml_context; a: Pggml_tensor; op: ggml_op_pool; k0: Integer; k1: Integer; s0: Integer; s1: Integer; p0: Single; p1: Single): Pggml_tensor; cdecl;
  ggml_pool_2d_back: function(ctx: Pggml_context; a: Pggml_tensor; af: Pggml_tensor; op: ggml_op_pool; k0: Integer; k1: Integer; s0: Integer; s1: Integer; p0: Single; p1: Single): Pggml_tensor; cdecl;
  ggml_upscale: function(ctx: Pggml_context; a: Pggml_tensor; scale_factor: Integer): Pggml_tensor; cdecl;
  ggml_upscale_ext: function(ctx: Pggml_context; a: Pggml_tensor; ne0: Integer; ne1: Integer; ne2: Integer; ne3: Integer): Pggml_tensor; cdecl;
  ggml_pad: function(ctx: Pggml_context; a: Pggml_tensor; p0: Integer; p1: Integer; p2: Integer; p3: Integer): Pggml_tensor; cdecl;
  ggml_pad_reflect_1d: function(ctx: Pggml_context; a: Pggml_tensor; p0: Integer; p1: Integer): Pggml_tensor; cdecl;
  ggml_timestep_embedding: function(ctx: Pggml_context; timesteps: Pggml_tensor; dim: Integer; max_period: Integer): Pggml_tensor; cdecl;
  ggml_argsort: function(ctx: Pggml_context; a: Pggml_tensor; order: ggml_sort_order): Pggml_tensor; cdecl;
  ggml_arange: function(ctx: Pggml_context; start: Single; stop: Single; step: Single): Pggml_tensor; cdecl;
  ggml_top_k: function(ctx: Pggml_context; a: Pggml_tensor; k: Integer): Pggml_tensor; cdecl;
  ggml_flash_attn_ext: function(ctx: Pggml_context; q: Pggml_tensor; k: Pggml_tensor; v: Pggml_tensor; mask: Pggml_tensor; scale: Single; max_bias: Single; logit_softcap: Single): Pggml_tensor; cdecl;
  ggml_flash_attn_ext_set_prec: procedure(a: Pggml_tensor; prec: ggml_prec); cdecl;
  ggml_flash_attn_ext_get_prec: function(const a: Pggml_tensor): ggml_prec; cdecl;
  ggml_flash_attn_back: function(ctx: Pggml_context; q: Pggml_tensor; k: Pggml_tensor; v: Pggml_tensor; d: Pggml_tensor; masked: Boolean): Pggml_tensor; cdecl;
  ggml_ssm_conv: function(ctx: Pggml_context; sx: Pggml_tensor; c: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_ssm_scan: function(ctx: Pggml_context; s: Pggml_tensor; x: Pggml_tensor; dt: Pggml_tensor; A: Pggml_tensor; B: Pggml_tensor; C: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_win_part: function(ctx: Pggml_context; a: Pggml_tensor; w: Integer): Pggml_tensor; cdecl;
  ggml_win_unpart: function(ctx: Pggml_context; a: Pggml_tensor; w0: Integer; h0: Integer; w: Integer): Pggml_tensor; cdecl;
  ggml_unary: function(ctx: Pggml_context; a: Pggml_tensor; op: ggml_unary_op): Pggml_tensor; cdecl;
  ggml_unary_inplace: function(ctx: Pggml_context; a: Pggml_tensor; op: ggml_unary_op): Pggml_tensor; cdecl;
  ggml_get_rel_pos: function(ctx: Pggml_context; a: Pggml_tensor; qh: Integer; kh: Integer): Pggml_tensor; cdecl;
  ggml_add_rel_pos: function(ctx: Pggml_context; a: Pggml_tensor; pw: Pggml_tensor; ph: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_add_rel_pos_inplace: function(ctx: Pggml_context; a: Pggml_tensor; pw: Pggml_tensor; ph: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_rwkv_wkv6: function(ctx: Pggml_context; k: Pggml_tensor; v: Pggml_tensor; r: Pggml_tensor; tf: Pggml_tensor; td: Pggml_tensor; state: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_map_unary_f32: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_unary_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_unary_inplace_f32: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_unary_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_binary_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_binary_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_binary_inplace_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_binary_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom1_f32: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_custom1_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom1_inplace_f32: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_custom1_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom2_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_custom2_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom2_inplace_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_custom2_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom3_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; fun: ggml_custom3_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom3_inplace_f32: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; fun: ggml_custom3_op_f32_t): Pggml_tensor; cdecl;
  ggml_map_custom1: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_custom1_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_map_custom1_inplace: function(ctx: Pggml_context; a: Pggml_tensor; fun: ggml_custom1_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_map_custom2: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_custom2_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_map_custom2_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; fun: ggml_custom2_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_map_custom3: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; fun: ggml_custom3_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_map_custom3_inplace: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor; fun: ggml_custom3_op_t; n_tasks: Integer; userdata: Pointer): Pggml_tensor; cdecl;
  ggml_cross_entropy_loss: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_cross_entropy_loss_back: function(ctx: Pggml_context; a: Pggml_tensor; b: Pggml_tensor; c: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_opt_step_adamw: function(ctx: Pggml_context; a: Pggml_tensor; grad: Pggml_tensor; m: Pggml_tensor; v: Pggml_tensor; adamw_params: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_build_forward_expand: procedure(cgraph: Pggml_cgraph; tensor: Pggml_tensor); cdecl;
  ggml_build_backward_expand: procedure(ctx_static: Pggml_context; ctx_compute: Pggml_context; cgraph: Pggml_cgraph; accumulate: Boolean); cdecl;
  ggml_new_graph: function(ctx: Pggml_context): Pggml_cgraph; cdecl;
  ggml_new_graph_custom: function(ctx: Pggml_context; size: NativeUInt; grads: Boolean): Pggml_cgraph; cdecl;
  ggml_graph_dup: function(ctx: Pggml_context; cgraph: Pggml_cgraph): Pggml_cgraph; cdecl;
  ggml_graph_cpy: procedure(src: Pggml_cgraph; dst: Pggml_cgraph); cdecl;
  ggml_graph_reset: procedure(cgraph: Pggml_cgraph); cdecl;
  ggml_graph_clear: procedure(cgraph: Pggml_cgraph); cdecl;
  ggml_graph_size: function(cgraph: Pggml_cgraph): Integer; cdecl;
  ggml_graph_node: function(cgraph: Pggml_cgraph; i: Integer): Pggml_tensor; cdecl;
  ggml_graph_nodes: function(cgraph: Pggml_cgraph): PPggml_tensor; cdecl;
  ggml_graph_n_nodes: function(cgraph: Pggml_cgraph): Integer; cdecl;
  ggml_graph_add_node: procedure(cgraph: Pggml_cgraph; tensor: Pggml_tensor); cdecl;
  ggml_graph_overhead: function(): NativeUInt; cdecl;
  ggml_graph_overhead_custom: function(size: NativeUInt; grads: Boolean): NativeUInt; cdecl;
  ggml_graph_get_tensor: function(const cgraph: Pggml_cgraph; const name: PUTF8Char): Pggml_tensor; cdecl;
  ggml_graph_get_grad: function(const cgraph: Pggml_cgraph; const node: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_graph_get_grad_acc: function(const cgraph: Pggml_cgraph; const node: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_graph_print: procedure(const cgraph: Pggml_cgraph); cdecl;
  ggml_graph_dump_dot: procedure(const gb: Pggml_cgraph; const gf: Pggml_cgraph; const filename: PUTF8Char); cdecl;
  ggml_log_set: procedure(log_callback: ggml_log_callback; user_data: Pointer); cdecl;
  ggml_set_zero: function(tensor: Pggml_tensor): Pggml_tensor; cdecl;
  ggml_quantize_init: procedure(&type: ggml_type); cdecl;
  ggml_quantize_free: procedure(); cdecl;
  ggml_quantize_requires_imatrix: function(&type: ggml_type): Boolean; cdecl;
  ggml_quantize_chunk: function(&type: ggml_type; const src: PSingle; dst: Pointer; start: Int64; nrows: Int64; n_per_row: Int64; const imatrix: PSingle): NativeUInt; cdecl;
  gguf_init_empty: function(): Pgguf_context; cdecl;
  gguf_init_from_file: function(const fname: PUTF8Char; params: gguf_init_params): Pgguf_context; cdecl;
  gguf_free: procedure(ctx: Pgguf_context); cdecl;
  gguf_type_name: function(&type: gguf_type): PUTF8Char; cdecl;
  gguf_get_version: function(const ctx: Pgguf_context): Integer; cdecl;
  gguf_get_alignment: function(const ctx: Pgguf_context): NativeUInt; cdecl;
  gguf_get_data_offset: function(const ctx: Pgguf_context): NativeUInt; cdecl;
  gguf_get_data: function(const ctx: Pgguf_context): Pointer; cdecl;
  gguf_get_n_kv: function(const ctx: Pgguf_context): Integer; cdecl;
  gguf_find_key: function(const ctx: Pgguf_context; const key: PUTF8Char): Integer; cdecl;
  gguf_get_key: function(const ctx: Pgguf_context; key_id: Integer): PUTF8Char; cdecl;
  gguf_get_kv_type: function(const ctx: Pgguf_context; key_id: Integer): gguf_type; cdecl;
  gguf_get_arr_type: function(const ctx: Pgguf_context; key_id: Integer): gguf_type; cdecl;
  gguf_get_val_u8: function(const ctx: Pgguf_context; key_id: Integer): UInt8; cdecl;
  gguf_get_val_i8: function(const ctx: Pgguf_context; key_id: Integer): Int8; cdecl;
  gguf_get_val_u16: function(const ctx: Pgguf_context; key_id: Integer): UInt16; cdecl;
  gguf_get_val_i16: function(const ctx: Pgguf_context; key_id: Integer): Int16; cdecl;
  gguf_get_val_u32: function(const ctx: Pgguf_context; key_id: Integer): UInt32; cdecl;
  gguf_get_val_i32: function(const ctx: Pgguf_context; key_id: Integer): Int32; cdecl;
  gguf_get_val_f32: function(const ctx: Pgguf_context; key_id: Integer): Single; cdecl;
  gguf_get_val_u64: function(const ctx: Pgguf_context; key_id: Integer): UInt64; cdecl;
  gguf_get_val_i64: function(const ctx: Pgguf_context; key_id: Integer): Int64; cdecl;
  gguf_get_val_f64: function(const ctx: Pgguf_context; key_id: Integer): Double; cdecl;
  gguf_get_val_bool: function(const ctx: Pgguf_context; key_id: Integer): Boolean; cdecl;
  gguf_get_val_str: function(const ctx: Pgguf_context; key_id: Integer): PUTF8Char; cdecl;
  gguf_get_val_data: function(const ctx: Pgguf_context; key_id: Integer): Pointer; cdecl;
  gguf_get_arr_n: function(const ctx: Pgguf_context; key_id: Integer): Integer; cdecl;
  gguf_get_arr_data: function(const ctx: Pgguf_context; key_id: Integer): Pointer; cdecl;
  gguf_get_arr_str: function(const ctx: Pgguf_context; key_id: Integer; i: Integer): PUTF8Char; cdecl;
  gguf_get_n_tensors: function(const ctx: Pgguf_context): Integer; cdecl;
  gguf_find_tensor: function(const ctx: Pgguf_context; const name: PUTF8Char): Integer; cdecl;
  gguf_get_tensor_offset: function(const ctx: Pgguf_context; i: Integer): NativeUInt; cdecl;
  gguf_get_tensor_name: function(const ctx: Pgguf_context; i: Integer): PUTF8Char; cdecl;
  gguf_get_tensor_type: function(const ctx: Pgguf_context; i: Integer): ggml_type; cdecl;
  gguf_remove_key: procedure(ctx: Pgguf_context; const key: PUTF8Char); cdecl;
  gguf_set_val_u8: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: UInt8); cdecl;
  gguf_set_val_i8: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Int8); cdecl;
  gguf_set_val_u16: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: UInt16); cdecl;
  gguf_set_val_i16: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Int16); cdecl;
  gguf_set_val_u32: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: UInt32); cdecl;
  gguf_set_val_i32: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Int32); cdecl;
  gguf_set_val_f32: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Single); cdecl;
  gguf_set_val_u64: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: UInt64); cdecl;
  gguf_set_val_i64: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Int64); cdecl;
  gguf_set_val_f64: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Double); cdecl;
  gguf_set_val_bool: procedure(ctx: Pgguf_context; const key: PUTF8Char; val: Boolean); cdecl;
  gguf_set_val_str: procedure(ctx: Pgguf_context; const key: PUTF8Char; const val: PUTF8Char); cdecl;
  gguf_set_arr_data: procedure(ctx: Pgguf_context; const key: PUTF8Char; &type: gguf_type; const data: Pointer; n: Integer); cdecl;
  gguf_set_arr_str: procedure(ctx: Pgguf_context; const key: PUTF8Char; data: PPUTF8Char; n: Integer); cdecl;
  gguf_set_kv: procedure(ctx: Pgguf_context; src: Pgguf_context); cdecl;
  gguf_add_tensor: procedure(ctx: Pgguf_context; const tensor: Pggml_tensor); cdecl;
  gguf_set_tensor_type: procedure(ctx: Pgguf_context; const name: PUTF8Char; &type: ggml_type); cdecl;
  gguf_set_tensor_data: procedure(ctx: Pgguf_context; const name: PUTF8Char; const data: Pointer; size: NativeUInt); cdecl;
  gguf_write_to_file: procedure(const ctx: Pgguf_context; const fname: PUTF8Char; only_meta: Boolean); cdecl;
  gguf_get_meta_size: function(const ctx: Pgguf_context): NativeUInt; cdecl;
  gguf_get_meta_data: procedure(const ctx: Pgguf_context; data: Pointer); cdecl;
  ggml_get_type_traits: function(&type: ggml_type): Pggml_type_traits; cdecl;
  ggml_threadpool_params_default: function(n_threads: Integer): ggml_threadpool_params; cdecl;
  ggml_threadpool_params_init: procedure(p: Pggml_threadpool_params; n_threads: Integer); cdecl;
  ggml_threadpool_params_match: function(const p0: Pggml_threadpool_params; const p1: Pggml_threadpool_params): Boolean; cdecl;
  ggml_tallocr_new: function(buffer: ggml_backend_buffer_t): ggml_tallocr; cdecl;
  ggml_tallocr_alloc: procedure(talloc: Pggml_tallocr; tensor: Pggml_tensor); cdecl;
  ggml_gallocr_new: function(buft: ggml_backend_buffer_type_t): ggml_gallocr_t; cdecl;
  ggml_gallocr_new_n: function(bufts: Pggml_backend_buffer_type_t; n_bufs: Integer): ggml_gallocr_t; cdecl;
  ggml_gallocr_free: procedure(galloc: ggml_gallocr_t); cdecl;
  ggml_gallocr_reserve: function(galloc: ggml_gallocr_t; graph: Pggml_cgraph): Boolean; cdecl;
  ggml_gallocr_reserve_n: function(galloc: ggml_gallocr_t; graph: Pggml_cgraph; const node_buffer_ids: PInteger; const leaf_buffer_ids: PInteger): Boolean; cdecl;
  ggml_gallocr_alloc_graph: function(galloc: ggml_gallocr_t; graph: Pggml_cgraph): Boolean; cdecl;
  ggml_gallocr_get_buffer_size: function(galloc: ggml_gallocr_t; buffer_id: Integer): NativeUInt; cdecl;
  ggml_backend_alloc_ctx_tensors_from_buft: function(ctx: Pggml_context; buft: ggml_backend_buffer_type_t): Pggml_backend_buffer; cdecl;
  ggml_backend_alloc_ctx_tensors: function(ctx: Pggml_context; backend: ggml_backend_t): Pggml_backend_buffer; cdecl;
  ggml_backend_buft_name: function(buft: ggml_backend_buffer_type_t): PUTF8Char; cdecl;
  ggml_backend_buft_alloc_buffer: function(buft: ggml_backend_buffer_type_t; size: NativeUInt): ggml_backend_buffer_t; cdecl;
  ggml_backend_buft_get_alignment: function(buft: ggml_backend_buffer_type_t): NativeUInt; cdecl;
  ggml_backend_buft_get_max_size: function(buft: ggml_backend_buffer_type_t): NativeUInt; cdecl;
  ggml_backend_buft_get_alloc_size: function(buft: ggml_backend_buffer_type_t; tensor: Pggml_tensor): NativeUInt; cdecl;
  ggml_backend_buft_is_host: function(buft: ggml_backend_buffer_type_t): Boolean; cdecl;
  ggml_backend_buft_get_device: function(buft: ggml_backend_buffer_type_t): ggml_backend_dev_t; cdecl;
  ggml_backend_buffer_name: function(buffer: ggml_backend_buffer_t): PUTF8Char; cdecl;
  ggml_backend_buffer_free: procedure(buffer: ggml_backend_buffer_t); cdecl;
  ggml_backend_buffer_get_base: function(buffer: ggml_backend_buffer_t): Pointer; cdecl;
  ggml_backend_buffer_get_size: function(buffer: ggml_backend_buffer_t): NativeUInt; cdecl;
  ggml_backend_buffer_init_tensor: procedure(buffer: ggml_backend_buffer_t; tensor: Pggml_tensor); cdecl;
  ggml_backend_buffer_get_alignment: function(buffer: ggml_backend_buffer_t): NativeUInt; cdecl;
  ggml_backend_buffer_get_max_size: function(buffer: ggml_backend_buffer_t): NativeUInt; cdecl;
  ggml_backend_buffer_get_alloc_size: function(buffer: ggml_backend_buffer_t; tensor: Pggml_tensor): NativeUInt; cdecl;
  ggml_backend_buffer_clear: procedure(buffer: ggml_backend_buffer_t; value: UInt8); cdecl;
  ggml_backend_buffer_is_host: function(buffer: ggml_backend_buffer_t): Boolean; cdecl;
  ggml_backend_buffer_set_usage: procedure(buffer: ggml_backend_buffer_t; usage: ggml_backend_buffer_usage); cdecl;
  ggml_backend_buffer_get_usage: function(buffer: ggml_backend_buffer_t): ggml_backend_buffer_usage; cdecl;
  ggml_backend_buffer_get_type: function(buffer: ggml_backend_buffer_t): ggml_backend_buffer_type_t; cdecl;
  ggml_backend_buffer_reset: procedure(buffer: ggml_backend_buffer_t); cdecl;
  ggml_backend_tensor_copy: procedure(src: Pggml_tensor; dst: Pggml_tensor); cdecl;
  ggml_backend_guid: function(backend: ggml_backend_t): ggml_guid_t; cdecl;
  ggml_backend_name: function(backend: ggml_backend_t): PUTF8Char; cdecl;
  ggml_backend_free: procedure(backend: ggml_backend_t); cdecl;
  ggml_backend_get_default_buffer_type: function(backend: ggml_backend_t): ggml_backend_buffer_type_t; cdecl;
  ggml_backend_alloc_buffer: function(backend: ggml_backend_t; size: NativeUInt): ggml_backend_buffer_t; cdecl;
  ggml_backend_get_alignment: function(backend: ggml_backend_t): NativeUInt; cdecl;
  ggml_backend_get_max_size: function(backend: ggml_backend_t): NativeUInt; cdecl;
  ggml_backend_tensor_set_async: procedure(backend: ggml_backend_t; tensor: Pggml_tensor; const data: Pointer; offset: NativeUInt; size: NativeUInt); cdecl;
  ggml_backend_tensor_get_async: procedure(backend: ggml_backend_t; const tensor: Pggml_tensor; data: Pointer; offset: NativeUInt; size: NativeUInt); cdecl;
  ggml_backend_tensor_set: procedure(tensor: Pggml_tensor; const data: Pointer; offset: NativeUInt; size: NativeUInt); cdecl;
  ggml_backend_tensor_get: procedure(const tensor: Pggml_tensor; data: Pointer; offset: NativeUInt; size: NativeUInt); cdecl;
  ggml_backend_tensor_memset: procedure(tensor: Pggml_tensor; value: UInt8; offset: NativeUInt; size: NativeUInt); cdecl;
  ggml_backend_synchronize: procedure(backend: ggml_backend_t); cdecl;
  ggml_backend_graph_plan_create: function(backend: ggml_backend_t; cgraph: Pggml_cgraph): ggml_backend_graph_plan_t; cdecl;
  ggml_backend_graph_plan_free: procedure(backend: ggml_backend_t; plan: ggml_backend_graph_plan_t); cdecl;
  ggml_backend_graph_plan_compute: function(backend: ggml_backend_t; plan: ggml_backend_graph_plan_t): ggml_status; cdecl;
  ggml_backend_graph_compute: function(backend: ggml_backend_t; cgraph: Pggml_cgraph): ggml_status; cdecl;
  ggml_backend_graph_compute_async: function(backend: ggml_backend_t; cgraph: Pggml_cgraph): ggml_status; cdecl;
  ggml_backend_supports_op: function(backend: ggml_backend_t; const op: Pggml_tensor): Boolean; cdecl;
  ggml_backend_supports_buft: function(backend: ggml_backend_t; buft: ggml_backend_buffer_type_t): Boolean; cdecl;
  ggml_backend_offload_op: function(backend: ggml_backend_t; const op: Pggml_tensor): Boolean; cdecl;
  ggml_backend_tensor_copy_async: procedure(backend_src: ggml_backend_t; backend_dst: ggml_backend_t; src: Pggml_tensor; dst: Pggml_tensor); cdecl;
  ggml_backend_get_device: function(backend: ggml_backend_t): ggml_backend_dev_t; cdecl;
  ggml_backend_event_new: function(device: ggml_backend_dev_t): ggml_backend_event_t; cdecl;
  ggml_backend_event_free: procedure(event: ggml_backend_event_t); cdecl;
  ggml_backend_event_record: procedure(event: ggml_backend_event_t; backend: ggml_backend_t); cdecl;
  ggml_backend_event_synchronize: procedure(event: ggml_backend_event_t); cdecl;
  ggml_backend_event_wait: procedure(backend: ggml_backend_t; event: ggml_backend_event_t); cdecl;
  ggml_backend_dev_name: function(device: ggml_backend_dev_t): PUTF8Char; cdecl;
  ggml_backend_dev_description: function(device: ggml_backend_dev_t): PUTF8Char; cdecl;
  ggml_backend_dev_memory: procedure(device: ggml_backend_dev_t; free: PNativeUInt; total: PNativeUInt); cdecl;
  ggml_backend_dev_type_rtn: function(device: ggml_backend_dev_t): ggml_backend_dev_type; cdecl;
  ggml_backend_dev_get_props: procedure(device: ggml_backend_dev_t; props: Pggml_backend_dev_props); cdecl;
  ggml_backend_dev_backend_reg: function(device: ggml_backend_dev_t): ggml_backend_reg_t; cdecl;
  ggml_backend_dev_init: function(device: ggml_backend_dev_t; const params: PUTF8Char): ggml_backend_t; cdecl;
  ggml_backend_dev_buffer_type: function(device: ggml_backend_dev_t): ggml_backend_buffer_type_t; cdecl;
  ggml_backend_dev_host_buffer_type: function(device: ggml_backend_dev_t): ggml_backend_buffer_type_t; cdecl;
  ggml_backend_dev_buffer_from_host_ptr: function(device: ggml_backend_dev_t; ptr: Pointer; size: NativeUInt; max_tensor_size: NativeUInt): ggml_backend_buffer_t; cdecl;
  ggml_backend_dev_supports_op: function(device: ggml_backend_dev_t; const op: Pggml_tensor): Boolean; cdecl;
  ggml_backend_dev_supports_buft: function(device: ggml_backend_dev_t; buft: ggml_backend_buffer_type_t): Boolean; cdecl;
  ggml_backend_dev_offload_op: function(device: ggml_backend_dev_t; const op: Pggml_tensor): Boolean; cdecl;
  ggml_backend_reg_name: function(reg: ggml_backend_reg_t): PUTF8Char; cdecl;
  ggml_backend_reg_dev_count: function(reg: ggml_backend_reg_t): NativeUInt; cdecl;
  ggml_backend_reg_dev_get: function(reg: ggml_backend_reg_t; index: NativeUInt): ggml_backend_dev_t; cdecl;
  ggml_backend_reg_get_proc_address: function(reg: ggml_backend_reg_t; const name: PUTF8Char): Pointer; cdecl;
  ggml_backend_reg_count: function(): NativeUInt; cdecl;
  ggml_backend_reg_get: function(index: NativeUInt): ggml_backend_reg_t; cdecl;
  ggml_backend_reg_by_name: function(const name: PUTF8Char): ggml_backend_reg_t; cdecl;
  ggml_backend_dev_count: function(): NativeUInt; cdecl;
  ggml_backend_dev_get: function(index: NativeUInt): ggml_backend_dev_t; cdecl;
  ggml_backend_dev_by_name: function(const name: PUTF8Char): ggml_backend_dev_t; cdecl;
  ggml_backend_dev_by_type: function(&type: ggml_backend_dev_type): ggml_backend_dev_t; cdecl;
  ggml_backend_init_by_name: function(const name: PUTF8Char; const params: PUTF8Char): ggml_backend_t; cdecl;
  ggml_backend_init_by_type: function(&type: ggml_backend_dev_type; const params: PUTF8Char): ggml_backend_t; cdecl;
  ggml_backend_init_best: function(): ggml_backend_t; cdecl;
  ggml_backend_load: function(const path: PUTF8Char): ggml_backend_reg_t; cdecl;
  ggml_backend_unload: procedure(reg: ggml_backend_reg_t); cdecl;
  ggml_backend_load_all: procedure(); cdecl;
  ggml_backend_load_all_from_path: procedure(const dir_path: PUTF8Char); cdecl;
  ggml_backend_sched_new: function(backends: Pggml_backend_t; bufts: Pggml_backend_buffer_type_t; n_backends: Integer; graph_size: NativeUInt; parallel: Boolean): ggml_backend_sched_t; cdecl;
  ggml_backend_sched_free: procedure(sched: ggml_backend_sched_t); cdecl;
  ggml_backend_sched_reserve: function(sched: ggml_backend_sched_t; measure_graph: Pggml_cgraph): Boolean; cdecl;
  ggml_backend_sched_get_n_backends: function(sched: ggml_backend_sched_t): Integer; cdecl;
  ggml_backend_sched_get_backend: function(sched: ggml_backend_sched_t; i: Integer): ggml_backend_t; cdecl;
  ggml_backend_sched_get_n_splits: function(sched: ggml_backend_sched_t): Integer; cdecl;
  ggml_backend_sched_get_n_copies: function(sched: ggml_backend_sched_t): Integer; cdecl;
  ggml_backend_sched_get_buffer_size: function(sched: ggml_backend_sched_t; backend: ggml_backend_t): NativeUInt; cdecl;
  ggml_backend_sched_set_tensor_backend: procedure(sched: ggml_backend_sched_t; node: Pggml_tensor; backend: ggml_backend_t); cdecl;
  ggml_backend_sched_get_tensor_backend: function(sched: ggml_backend_sched_t; node: Pggml_tensor): ggml_backend_t; cdecl;
  ggml_backend_sched_alloc_graph: function(sched: ggml_backend_sched_t; graph: Pggml_cgraph): Boolean; cdecl;
  ggml_backend_sched_graph_compute: function(sched: ggml_backend_sched_t; graph: Pggml_cgraph): ggml_status; cdecl;
  ggml_backend_sched_graph_compute_async: function(sched: ggml_backend_sched_t; graph: Pggml_cgraph): ggml_status; cdecl;
  ggml_backend_sched_synchronize: procedure(sched: ggml_backend_sched_t); cdecl;
  ggml_backend_sched_reset: procedure(sched: ggml_backend_sched_t); cdecl;
  ggml_backend_sched_set_eval_callback: procedure(sched: ggml_backend_sched_t; callback: ggml_backend_sched_eval_callback; user_data: Pointer); cdecl;
  ggml_backend_graph_copy_rtn: function(backend: ggml_backend_t; graph: Pggml_cgraph): ggml_backend_graph_copy; cdecl;
  ggml_backend_graph_copy_free: procedure(copy: ggml_backend_graph_copy); cdecl;
  ggml_backend_compare_graph_backend: function(backend1: ggml_backend_t; backend2: ggml_backend_t; graph: Pggml_cgraph; callback: ggml_backend_eval_callback; user_data: Pointer): Boolean; cdecl;
  ggml_backend_tensor_alloc: procedure(buffer: ggml_backend_buffer_t; tensor: Pggml_tensor; addr: Pointer); cdecl;
  ggml_backend_view_init: procedure(tensor: Pggml_tensor); cdecl;
  ggml_backend_cpu_buffer_from_ptr: function(ptr: Pointer; size: NativeUInt): ggml_backend_buffer_t; cdecl;
  ggml_backend_cpu_buffer_type: function(): ggml_backend_buffer_type_t; cdecl;
  ggml_numa_init: procedure(numa: ggml_numa_strategy); cdecl;
  ggml_is_numa: function(): Boolean; cdecl;
  ggml_new_i32: function(ctx: Pggml_context; value: Int32): Pggml_tensor; cdecl;
  ggml_new_f32: function(ctx: Pggml_context; value: Single): Pggml_tensor; cdecl;
  ggml_set_i32: function(tensor: Pggml_tensor; value: Int32): Pggml_tensor; cdecl;
  ggml_set_f32: function(tensor: Pggml_tensor; value: Single): Pggml_tensor; cdecl;
  ggml_get_i32_1d: function(const tensor: Pggml_tensor; i: Integer): Int32; cdecl;
  ggml_set_i32_1d: procedure(const tensor: Pggml_tensor; i: Integer; value: Int32); cdecl;
  ggml_get_i32_nd: function(const tensor: Pggml_tensor; i0: Integer; i1: Integer; i2: Integer; i3: Integer): Int32; cdecl;
  ggml_set_i32_nd: procedure(const tensor: Pggml_tensor; i0: Integer; i1: Integer; i2: Integer; i3: Integer; value: Int32); cdecl;
  ggml_get_f32_1d: function(const tensor: Pggml_tensor; i: Integer): Single; cdecl;
  ggml_set_f32_1d: procedure(const tensor: Pggml_tensor; i: Integer; value: Single); cdecl;
  ggml_get_f32_nd: function(const tensor: Pggml_tensor; i0: Integer; i1: Integer; i2: Integer; i3: Integer): Single; cdecl;
  ggml_set_f32_nd: procedure(const tensor: Pggml_tensor; i0: Integer; i1: Integer; i2: Integer; i3: Integer; value: Single); cdecl;
  ggml_threadpool_new: function(params: Pggml_threadpool_params): Pggml_threadpool; cdecl;
  ggml_threadpool_free: procedure(threadpool: Pggml_threadpool); cdecl;
  ggml_threadpool_pause: procedure(threadpool: Pggml_threadpool); cdecl;
  ggml_threadpool_resume: procedure(threadpool: Pggml_threadpool); cdecl;
  ggml_graph_plan: function(const cgraph: Pggml_cgraph; n_threads: Integer; threadpool: Pggml_threadpool): ggml_cplan; cdecl;
  ggml_graph_compute: function(cgraph: Pggml_cgraph; cplan: Pggml_cplan): ggml_status; cdecl;
  ggml_graph_compute_with_ctx: function(ctx: Pggml_context; cgraph: Pggml_cgraph; n_threads: Integer): ggml_status; cdecl;
  ggml_cpu_has_sse3: function(): Integer; cdecl;
  ggml_cpu_has_ssse3: function(): Integer; cdecl;
  ggml_cpu_has_avx: function(): Integer; cdecl;
  ggml_cpu_has_avx_vnni: function(): Integer; cdecl;
  ggml_cpu_has_avx2: function(): Integer; cdecl;
  ggml_cpu_has_f16c: function(): Integer; cdecl;
  ggml_cpu_has_fma: function(): Integer; cdecl;
  ggml_cpu_has_avx512: function(): Integer; cdecl;
  ggml_cpu_has_avx512_vbmi: function(): Integer; cdecl;
  ggml_cpu_has_avx512_vnni: function(): Integer; cdecl;
  ggml_cpu_has_avx512_bf16: function(): Integer; cdecl;
  ggml_cpu_has_amx_int8: function(): Integer; cdecl;
  ggml_cpu_has_neon: function(): Integer; cdecl;
  ggml_cpu_has_arm_fma: function(): Integer; cdecl;
  ggml_cpu_has_fp16_va: function(): Integer; cdecl;
  ggml_cpu_has_dotprod: function(): Integer; cdecl;
  ggml_cpu_has_matmul_int8: function(): Integer; cdecl;
  ggml_cpu_has_sve: function(): Integer; cdecl;
  ggml_cpu_get_sve_cnt: function(): Integer; cdecl;
  ggml_cpu_has_riscv_v: function(): Integer; cdecl;
  ggml_cpu_has_vsx: function(): Integer; cdecl;
  ggml_cpu_has_wasm_simd: function(): Integer; cdecl;
  ggml_cpu_has_llamafile: function(): Integer; cdecl;
  ggml_get_type_traits_cpu: function(&type: ggml_type): Pggml_type_traits_cpu; cdecl;
  ggml_cpu_init: procedure(); cdecl;
  ggml_backend_cpu_init: function(): ggml_backend_t; cdecl;
  ggml_backend_is_cpu: function(backend: ggml_backend_t): Boolean; cdecl;
  ggml_backend_cpu_set_n_threads: procedure(backend_cpu: ggml_backend_t; n_threads: Integer); cdecl;
  ggml_backend_cpu_set_threadpool: procedure(backend_cpu: ggml_backend_t; threadpool: ggml_threadpool_t); cdecl;
  ggml_backend_cpu_set_abort_callback: procedure(backend_cpu: ggml_backend_t; abort_callback: ggml_abort_callback; abort_callback_data: Pointer); cdecl;
  ggml_backend_cpu_reg: function(): ggml_backend_reg_t; cdecl;
  llama_model_default_params: function(): llama_model_params; cdecl;
  llama_context_default_params: function(): llama_context_params; cdecl;
  llama_sampler_chain_default_params: function(): llama_sampler_chain_params; cdecl;
  llama_model_quantize_default_params: function(): llama_model_quantize_params; cdecl;
  llama_backend_init: procedure(); cdecl;
  llama_numa_init: procedure(numa: ggml_numa_strategy); cdecl;
  llama_attach_threadpool: procedure(ctx: Pllama_context; threadpool: ggml_threadpool_t; threadpool_batch: ggml_threadpool_t); cdecl;
  llama_detach_threadpool: procedure(ctx: Pllama_context); cdecl;
  llama_backend_free: procedure(); cdecl;
  llama_load_model_from_file: function(const path_model: PUTF8Char; params: llama_model_params): Pllama_model; cdecl;
  llama_free_model: procedure(model: Pllama_model); cdecl;
  llama_new_context_with_model: function(model: Pllama_model; params: llama_context_params): Pllama_context; cdecl;
  llama_free: procedure(ctx: Pllama_context); cdecl;
  llama_time_us: function(): Int64; cdecl;
  llama_max_devices: function(): NativeUInt; cdecl;
  llama_supports_mmap: function(): Boolean; cdecl;
  llama_supports_mlock: function(): Boolean; cdecl;
  llama_supports_gpu_offload: function(): Boolean; cdecl;
  llama_supports_rpc: function(): Boolean; cdecl;
  llama_n_ctx: function(const ctx: Pllama_context): UInt32; cdecl;
  llama_n_batch: function(const ctx: Pllama_context): UInt32; cdecl;
  llama_n_ubatch: function(const ctx: Pllama_context): UInt32; cdecl;
  llama_n_seq_max: function(const ctx: Pllama_context): UInt32; cdecl;
  llama_n_vocab: function(const model: Pllama_model): Int32; cdecl;
  llama_n_ctx_train: function(const model: Pllama_model): Int32; cdecl;
  llama_n_embd: function(const model: Pllama_model): Int32; cdecl;
  llama_n_layer: function(const model: Pllama_model): Int32; cdecl;
  llama_n_head: function(const model: Pllama_model): Int32; cdecl;
  llama_get_model: function(const ctx: Pllama_context): Pllama_model; cdecl;
  llama_pooling_type_rtn: function(const ctx: Pllama_context): llama_pooling_type; cdecl;
  llama_vocab_type_rtn: function(const model: Pllama_model): llama_vocab_type; cdecl;
  llama_rope_type_rtn: function(const model: Pllama_model): llama_rope_type; cdecl;
  llama_rope_freq_scale_train: function(const model: Pllama_model): Single; cdecl;
  llama_model_meta_val_str: function(const model: Pllama_model; const key: PUTF8Char; buf: PUTF8Char; buf_size: NativeUInt): Int32; cdecl;
  llama_model_meta_count: function(const model: Pllama_model): Int32; cdecl;
  llama_model_meta_key_by_index: function(const model: Pllama_model; i: Int32; buf: PUTF8Char; buf_size: NativeUInt): Int32; cdecl;
  llama_model_meta_val_str_by_index: function(const model: Pllama_model; i: Int32; buf: PUTF8Char; buf_size: NativeUInt): Int32; cdecl;
  llama_model_desc: function(const model: Pllama_model; buf: PUTF8Char; buf_size: NativeUInt): Int32; cdecl;
  llama_model_size: function(const model: Pllama_model): UInt64; cdecl;
  llama_model_n_params: function(const model: Pllama_model): UInt64; cdecl;
  llama_model_has_encoder: function(const model: Pllama_model): Boolean; cdecl;
  llama_model_has_decoder: function(const model: Pllama_model): Boolean; cdecl;
  llama_model_decoder_start_token: function(const model: Pllama_model): llama_token; cdecl;
  llama_model_is_recurrent: function(const model: Pllama_model): Boolean; cdecl;
  llama_model_quantize: function(const fname_inp: PUTF8Char; const fname_out: PUTF8Char; const params: Pllama_model_quantize_params): UInt32; cdecl;
  llama_lora_adapter_init: function(model: Pllama_model; const path_lora: PUTF8Char): Pllama_lora_adapter; cdecl;
  llama_lora_adapter_set: function(ctx: Pllama_context; adapter: Pllama_lora_adapter; scale: Single): Int32; cdecl;
  llama_lora_adapter_remove: function(ctx: Pllama_context; adapter: Pllama_lora_adapter): Int32; cdecl;
  llama_lora_adapter_clear: procedure(ctx: Pllama_context); cdecl;
  llama_lora_adapter_free: procedure(adapter: Pllama_lora_adapter); cdecl;
  llama_control_vector_apply: function(lctx: Pllama_context; const data: PSingle; len: NativeUInt; n_embd: Int32; il_start: Int32; il_end: Int32): Int32; cdecl;
  llama_kv_cache_view_init: function(const ctx: Pllama_context; n_seq_max: Int32): llama_kv_cache_view; cdecl;
  llama_kv_cache_view_free: procedure(view: Pllama_kv_cache_view); cdecl;
  llama_kv_cache_view_update: procedure(const ctx: Pllama_context; view: Pllama_kv_cache_view); cdecl;
  llama_get_kv_cache_token_count: function(const ctx: Pllama_context): Int32; cdecl;
  llama_get_kv_cache_used_cells: function(const ctx: Pllama_context): Int32; cdecl;
  llama_kv_cache_clear: procedure(ctx: Pllama_context); cdecl;
  llama_kv_cache_seq_rm: function(ctx: Pllama_context; seq_id: llama_seq_id; p0: llama_pos; p1: llama_pos): Boolean; cdecl;
  llama_kv_cache_seq_cp: procedure(ctx: Pllama_context; seq_id_src: llama_seq_id; seq_id_dst: llama_seq_id; p0: llama_pos; p1: llama_pos); cdecl;
  llama_kv_cache_seq_keep: procedure(ctx: Pllama_context; seq_id: llama_seq_id); cdecl;
  llama_kv_cache_seq_add: procedure(ctx: Pllama_context; seq_id: llama_seq_id; p0: llama_pos; p1: llama_pos; delta: llama_pos); cdecl;
  llama_kv_cache_seq_div: procedure(ctx: Pllama_context; seq_id: llama_seq_id; p0: llama_pos; p1: llama_pos; d: Integer); cdecl;
  llama_kv_cache_seq_pos_max: function(ctx: Pllama_context; seq_id: llama_seq_id): llama_pos; cdecl;
  llama_kv_cache_defrag: procedure(ctx: Pllama_context); cdecl;
  llama_kv_cache_update: procedure(ctx: Pllama_context); cdecl;
  llama_kv_cache_can_shift: function(ctx: Pllama_context): Boolean; cdecl;
  llama_state_get_size: function(ctx: Pllama_context): NativeUInt; cdecl;
  llama_get_state_size: function(ctx: Pllama_context): NativeUInt; cdecl;
  llama_state_get_data: function(ctx: Pllama_context; dst: PUInt8; size: NativeUInt): NativeUInt; cdecl;
  llama_copy_state_data: function(ctx: Pllama_context; dst: PUInt8): NativeUInt; cdecl;
  llama_state_set_data: function(ctx: Pllama_context; const src: PUInt8; size: NativeUInt): NativeUInt; cdecl;
  llama_set_state_data: function(ctx: Pllama_context; const src: PUInt8): NativeUInt; cdecl;
  llama_state_load_file: function(ctx: Pllama_context; const path_session: PUTF8Char; tokens_out: Pllama_token; n_token_capacity: NativeUInt; n_token_count_out: PNativeUInt): Boolean; cdecl;
  llama_load_session_file: function(ctx: Pllama_context; const path_session: PUTF8Char; tokens_out: Pllama_token; n_token_capacity: NativeUInt; n_token_count_out: PNativeUInt): Boolean; cdecl;
  llama_state_save_file: function(ctx: Pllama_context; const path_session: PUTF8Char; const tokens: Pllama_token; n_token_count: NativeUInt): Boolean; cdecl;
  llama_save_session_file: function(ctx: Pllama_context; const path_session: PUTF8Char; const tokens: Pllama_token; n_token_count: NativeUInt): Boolean; cdecl;
  llama_state_seq_get_size: function(ctx: Pllama_context; seq_id: llama_seq_id): NativeUInt; cdecl;
  llama_state_seq_get_data: function(ctx: Pllama_context; dst: PUInt8; size: NativeUInt; seq_id: llama_seq_id): NativeUInt; cdecl;
  llama_state_seq_set_data: function(ctx: Pllama_context; const src: PUInt8; size: NativeUInt; dest_seq_id: llama_seq_id): NativeUInt; cdecl;
  llama_state_seq_save_file: function(ctx: Pllama_context; const filepath: PUTF8Char; seq_id: llama_seq_id; const tokens: Pllama_token; n_token_count: NativeUInt): NativeUInt; cdecl;
  llama_state_seq_load_file: function(ctx: Pllama_context; const filepath: PUTF8Char; dest_seq_id: llama_seq_id; tokens_out: Pllama_token; n_token_capacity: NativeUInt; n_token_count_out: PNativeUInt): NativeUInt; cdecl;
  llama_batch_get_one: function(tokens: Pllama_token; n_tokens: Int32): llama_batch; cdecl;
  llama_batch_init: function(n_tokens: Int32; embd: Int32; n_seq_max: Int32): llama_batch; cdecl;
  llama_batch_free: procedure(batch: llama_batch); cdecl;
  llama_encode: function(ctx: Pllama_context; batch: llama_batch): Int32; cdecl;
  llama_decode: function(ctx: Pllama_context; batch: llama_batch): Int32; cdecl;
  llama_set_n_threads: procedure(ctx: Pllama_context; n_threads: Int32; n_threads_batch: Int32); cdecl;
  llama_n_threads: function(ctx: Pllama_context): Int32; cdecl;
  llama_n_threads_batch: function(ctx: Pllama_context): Int32; cdecl;
  llama_set_embeddings: procedure(ctx: Pllama_context; embeddings: Boolean); cdecl;
  llama_set_causal_attn: procedure(ctx: Pllama_context; causal_attn: Boolean); cdecl;
  llama_set_abort_callback: procedure(ctx: Pllama_context; abort_callback: ggml_abort_callback; abort_callback_data: Pointer); cdecl;
  llama_synchronize: procedure(ctx: Pllama_context); cdecl;
  llama_get_logits: function(ctx: Pllama_context): PSingle; cdecl;
  llama_get_logits_ith: function(ctx: Pllama_context; i: Int32): PSingle; cdecl;
  llama_get_embeddings: function(ctx: Pllama_context): PSingle; cdecl;
  llama_get_embeddings_ith: function(ctx: Pllama_context; i: Int32): PSingle; cdecl;
  llama_get_embeddings_seq: function(ctx: Pllama_context; seq_id: llama_seq_id): PSingle; cdecl;
  llama_token_get_text: function(const model: Pllama_model; token: llama_token): PUTF8Char; cdecl;
  llama_token_get_score: function(const model: Pllama_model; token: llama_token): Single; cdecl;
  llama_token_get_attr: function(const model: Pllama_model; token: llama_token): llama_token_attr; cdecl;
  llama_token_is_eog: function(const model: Pllama_model; token: llama_token): Boolean; cdecl;
  llama_token_is_control: function(const model: Pllama_model; token: llama_token): Boolean; cdecl;
  llama_token_bos: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_eos: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_eot: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_cls: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_sep: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_nl: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_pad: function(const model: Pllama_model): llama_token; cdecl;
  llama_add_bos_token: function(const model: Pllama_model): Boolean; cdecl;
  llama_add_eos_token: function(const model: Pllama_model): Boolean; cdecl;
  llama_token_prefix: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_middle: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_suffix: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_pre: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_suf: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_mid: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_pad: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_rep: function(const model: Pllama_model): llama_token; cdecl;
  llama_token_fim_sep: function(const model: Pllama_model): llama_token; cdecl;
  llama_tokenize: function(const model: Pllama_model; const text: PUTF8Char; text_len: Int32; tokens: Pllama_token; n_tokens_max: Int32; add_special: Boolean; parse_special: Boolean): Int32; cdecl;
  llama_token_to_piece: function(const model: Pllama_model; token: llama_token; buf: PUTF8Char; length: Int32; lstrip: Int32; special: Boolean): Int32; cdecl;
  llama_detokenize: function(const model: Pllama_model; const tokens: Pllama_token; n_tokens: Int32; text: PUTF8Char; text_len_max: Int32; remove_special: Boolean; unparse_special: Boolean): Int32; cdecl;
  llama_chat_apply_template: function(const model: Pllama_model; const tmpl: PUTF8Char; const chat: Pllama_chat_message; n_msg: NativeUInt; add_ass: Boolean; buf: PUTF8Char; length: Int32): Int32; cdecl;
  llama_chat_builtin_templates: function(output: PPUTF8Char; len: NativeUInt): Int32; cdecl;
  llama_sampler_name: function(const smpl: Pllama_sampler): PUTF8Char; cdecl;
  llama_sampler_accept: procedure(smpl: Pllama_sampler; token: llama_token); cdecl;
  llama_sampler_apply: procedure(smpl: Pllama_sampler; cur_p: Pllama_token_data_array); cdecl;
  llama_sampler_reset: procedure(smpl: Pllama_sampler); cdecl;
  llama_sampler_clone: function(const smpl: Pllama_sampler): Pllama_sampler; cdecl;
  llama_sampler_free: procedure(smpl: Pllama_sampler); cdecl;
  llama_sampler_chain_init: function(params: llama_sampler_chain_params): Pllama_sampler; cdecl;
  llama_sampler_chain_add: procedure(chain: Pllama_sampler; smpl: Pllama_sampler); cdecl;
  llama_sampler_chain_get: function(const chain: Pllama_sampler; i: Int32): Pllama_sampler; cdecl;
  llama_sampler_chain_n: function(const chain: Pllama_sampler): Integer; cdecl;
  llama_sampler_chain_remove: function(chain: Pllama_sampler; i: Int32): Pllama_sampler; cdecl;
  llama_sampler_init_greedy: function(): Pllama_sampler; cdecl;
  llama_sampler_init_dist: function(seed: UInt32): Pllama_sampler; cdecl;
  llama_sampler_init_softmax: function(): Pllama_sampler; cdecl;
  llama_sampler_init_top_k: function(k: Int32): Pllama_sampler; cdecl;
  llama_sampler_init_top_p: function(p: Single; min_keep: NativeUInt): Pllama_sampler; cdecl;
  llama_sampler_init_min_p: function(p: Single; min_keep: NativeUInt): Pllama_sampler; cdecl;
  llama_sampler_init_typical: function(p: Single; min_keep: NativeUInt): Pllama_sampler; cdecl;
  llama_sampler_init_temp: function(t: Single): Pllama_sampler; cdecl;
  llama_sampler_init_temp_ext: function(t: Single; delta: Single; exponent: Single): Pllama_sampler; cdecl;
  llama_sampler_init_xtc: function(p: Single; t: Single; min_keep: NativeUInt; seed: UInt32): Pllama_sampler; cdecl;
  llama_sampler_init_mirostat: function(n_vocab: Int32; seed: UInt32; tau: Single; eta: Single; m: Int32): Pllama_sampler; cdecl;
  llama_sampler_init_mirostat_v2: function(seed: UInt32; tau: Single; eta: Single): Pllama_sampler; cdecl;
  llama_sampler_init_grammar: function(const model: Pllama_model; const grammar_str: PUTF8Char; const grammar_root: PUTF8Char): Pllama_sampler; cdecl;
  llama_sampler_init_penalties: function(penalty_last_n: Int32; penalty_repeat: Single; penalty_freq: Single; penalty_present: Single): Pllama_sampler; cdecl;
  llama_sampler_init_dry: function(const model: Pllama_model; dry_multiplier: Single; dry_base: Single; dry_allowed_length: Int32; dry_penalty_last_n: Int32; seq_breakers: PPUTF8Char; num_breakers: NativeUInt): Pllama_sampler; cdecl;
  llama_sampler_init_logit_bias: function(n_vocab: Int32; n_logit_bias: Int32; const logit_bias: Pllama_logit_bias): Pllama_sampler; cdecl;
  llama_sampler_init_infill: function(const model: Pllama_model): Pllama_sampler; cdecl;
  llama_sampler_get_seed: function(const smpl: Pllama_sampler): UInt32; cdecl;
  llama_sampler_sample: function(smpl: Pllama_sampler; ctx: Pllama_context; idx: Int32): llama_token; cdecl;
  llama_split_path: function(split_path: PUTF8Char; maxlen: NativeUInt; const path_prefix: PUTF8Char; split_no: Integer; split_count: Integer): Integer; cdecl;
  llama_split_prefix: function(split_prefix: PUTF8Char; maxlen: NativeUInt; const split_path: PUTF8Char; split_no: Integer; split_count: Integer): Integer; cdecl;
  llama_print_system_info: function(): PUTF8Char; cdecl;
  llama_log_set: procedure(log_callback: ggml_log_callback; user_data: Pointer); cdecl;
  llama_perf_context: function(const ctx: Pllama_context): llama_perf_context_data; cdecl;
  llama_perf_context_print: procedure(const ctx: Pllama_context); cdecl;
  llama_perf_context_reset: procedure(ctx: Pllama_context); cdecl;
  llama_perf_sampler: function(const chain: Pllama_sampler): llama_perf_sampler_data; cdecl;
  llama_perf_sampler_print: procedure(const chain: Pllama_sampler); cdecl;
  llama_perf_sampler_reset: procedure(chain: Pllama_sampler); cdecl;
  redirect_cerr_to_callback: procedure(callback: cerr_callback; user_data: Pointer); cdecl;
  restore_cerr: procedure(); cdecl;

procedure GetExports(const aDLLHandle: THandle);

{$ENDREGION}

{$REGION ' Lumina.Common '}
type
  { TCallback }
  TCallback<T> = record
    Handler: T;
    UserData: Pointer;
  end;

  { TBaseObject }
  TBaseObject = class(TObject)
  public
    constructor Create(); virtual;
    destructor Destroy(); override;
  end;

  { TTokenResponse }

  // AddToken return messages - for TResponse.AddToken
  //  paWait = No new (full) words, just wait for more incoming tokens
  //  Append = Append existing line with latest word
  //  NewLine = start new line then print the latest word
  TTokenPrintAction = (tpaWait, tpaAppend, tpaNewline);

  { TResponse
    Helper to handle incoming tokens during streaming
      Example uses:
      - Tabulate tokens into full words based on wordbreaks
      - Control wordwrap/linechanges for console or custom GUI without wordwrap functionality
        (Does change the print resolution from Token to logical words)
  }
  TTokenResponse = record
  private
    FRaw: string;                  // Full response as is
    FTokens: array of string;      // Actual tokens
    FMaxLineLength: Integer;       // Define confined space, in chars for fixed width font
    FWordBreaks: array of char;    // What is considered a logical word-break
    FLineBreaks: array of char;    // What is considered a logical line-break
    FWords: array of String;       // Response but as array of "words"
    FWord: string;                // Current word accumulating
    FLine: string;                // Current line accumulating
    FFinalized: Boolean;          // Know the finalization is done
    FRightMargin: Integer;
    function HandleLineBreaks(const AToken: string): Boolean;
    function SplitWord(const AWord: string; var APrefix, ASuffix: string): Boolean;
    function GetLineLengthMax(): Integer;
  public
    class operator Initialize (out ADest: TTokenResponse);
    procedure SetRightMargin(const AMargin: Integer);
    procedure SetMaxLineLength(const ALength: Integer);
    function AddToken(const aToken: string): TTokenPrintAction;
    function LastWord(const ATrimLeft: Boolean=False): string;
    function Finalize: Boolean;
  end;

procedure Pause();
function  AsUTF8(const AText: string): Pointer;
function  EnableVirtualTerminalProcessing(): DWORD;
function  ResourceExists(aInstance: THandle; const aResName: string): Boolean;
function  HasConsoleOutput: Boolean;
function  GetPhysicalProcessorCount(): DWORD;
procedure GetConsoleSize(AWidth: PInteger; AHeight: PInteger);
function  HasEnoughDiskSpace(const APath: string; ARequiredSpace: Int64): Boolean;

{$ENDREGION}

{$REGION ' Lumina '}
const
  CHATML_TEMPLATE = '<|im_start|>{role} {content}<|im_end|><|im_start|>assistant';
  GEMMA_TEMPLATE  = '<start_of_turn>{role} {content}<end_of_turn>';
  PHI_TEMPLATE    = '<|{role}|> {content}<|end|><|assistant|>';

type

  ///  <summary>
  ///    The <c>TLumina</c> class provides a robust, flexible, and feature-rich interface
  ///    for performing local generative AI inference using large language models (LLMs).
  ///    It encapsulates the complexities of model management, token processing, and
  ///    callback integration into an intuitive API.
  ///  </summary>
  ///  <remarks>
  ///    This class is designed for high-performance AI workloads, supporting multi-threading,
  ///    GPU acceleration, and customizable configurations. It includes advanced capabilities
  ///    such as progress reporting, cancellation handling, and detailed performance metrics.
  ///    <para>
  ///      Use this class to interact seamlessly with local language models, enabling applications
  ///      such as chatbots, code generators, and AI-assisted writing tools.
  ///    </para>
  ///  </remarks>
  TLumina = class(TObject)
  public type
    ///  <summary>
    ///    Represents a callback procedure that is invoked for every token generated by the model.
    ///  </summary>
    ///  <param name="AToken">
    ///    The text of the token generated during the inference process.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data, providing context to the callback handler.
    ///  </param>
    ///  <remarks>
    ///    Use this callback to handle or process individual tokens as they are generated,
    ///    enabling real-time streaming outputs or intermediate processing steps.
    ///  </remarks>
    NextTokenCallback = procedure(const AToken: string; const AUserData: Pointer);

    ///  <summary>
    ///    A callback function type that determines whether a long-running operation
    ///    should be canceled.
    ///  </summary>
    ///  <param name="AUserData">
    ///    A user-defined pointer to data that provides additional context to the callback.
    ///  </param>
    ///  <returns>
    ///    Returns <c>True</c> to indicate the operation should be canceled, or <c>False</c>
    ///    to allow it to continue.
    ///  </returns>
    ///  <remarks>
    ///    This is particularly useful for scenarios where user intervention is required to
    ///    interrupt lengthy processes, such as model loading or inference.
    ///  </remarks>
    CancelCallback = function(const AUserData: Pointer): Boolean;

    ///  <summary>
    ///    A callback procedure type that provides real-time progress updates for model loading.
    ///  </summary>
    ///  <param name="AModelFilename">
    ///    The filename of the model being processed. This helps identify the operation context
    ///    when multiple models are used.
    ///  </param>
    ///  <param name="AProgress">
    ///    A floating-point value between 0.0 and 100.0, representing the progress as a percentage.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data, providing context to the callback.
    ///  </param>
    ///  <remarks>
    ///    Use this callback to display progress bars, logs, or other user feedback mechanisms.
    ///  </remarks>
    ProgressCallback  = procedure(const AModelFilename: string; const AProgress: Single; const AUserData: Pointer);

    ///  <summary>
    ///    A callback procedure type used for delivering informational messages or
    ///    logs generated during model operations.
    ///  </summary>
    ///  <param name="AText">
    ///    The textual content of the message.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data, providing context to the callback.
    ///  </param>
    ///  <remarks>
    ///    This is useful for capturing logs or debug information during inference and other operations.
    ///  </remarks>
    InfoCallback = procedure(const AText: string; const AUserData: Pointer);

    ///  <summary>
    ///    A record containing detailed performance metrics for an inference operation.
    ///  </summary>
    ///  <remarks>
    ///    This record is returned after each inference operation to provide detailed insights
    ///    into the performance characteristics of the model.
    ///  </remarks>
    PerformanceResult = record
      ///  <summary>
      ///    The average number of tokens processed per second during inference.
      ///  </summary>
      TokensPerSecond: Double;

      ///  <summary>
      ///    The total number of input tokens supplied to the model.
      ///  </summary>
      TotalInputTokens: Int32;

      ///  <summary>
      ///    The total number of output tokens generated by the model.
      ///  </summary>
      TotalOutputTokens: Int32;
    end;
  private type
    TNextTokenCallback = TCallback<NextTokenCallback>;
    TCancelCallback = TCallback<CancelCallback>;
    TProgressCallback = TCallback<ProgressCallback>;
    TInfoCallback = TCallback<InfoCallback>;
  private
    FNextTokenCallback: TNextTokenCallback;
    FCancelCallback: TCancelCallback;
    FProgressCallback: TProgressCallback;
    FInfoCallback: TInfoCallback;
    FError: string;
    FPerf: TLumina.PerformanceResult;
    FModelParams: llama_model_params;
    FModel: Pllama_model;
    FModelFilename: string;
    FModelProgress: Single;
    FModelTemplate: string;
    FModelMaxContex: UInt32;
    FGPULayers: Int32;
    FMaxThreads: Int32;
    FLineOutputRightMargin: UInt32;
    FLineOutputMaxLineLength: UInt32;
    FTokenResponse: TTokenResponse;
    function  TokenToPiece(const AContext: Pllama_context; const AToken: llama_token; const ASpecial: Boolean): string;
    function  CalcPerformance(const AContext: Pllama_context): TLumina.PerformanceResult;
    procedure SetError(const AText: string; const AArgs: array of const);
    function  OnCancel(): Boolean;
    procedure OnNextToken(const AToken: string);
    procedure OnProgress(const AProgress: Single);
    procedure OnInfo(const AText: string);
  public
    ///  <summary>
    ///    Constructs a new instance of the <c>TLumina</c> class, initializing its internal state.
    ///  </summary>
    constructor Create(); virtual;

    ///  <summary>
    ///    Releases all resources held by the <c>TLumina</c> instance, including loaded models
    ///    and associated memory allocations.
    ///  </summary>
    destructor Destroy(); override;

    ///  <summary>
    ///    Logs a formatted message to the console or application-defined logging mechanism.
    ///  </summary>
    ///  <param name="AText">
    ///    A format string that defines the message content.
    ///  </param>
    ///  <param name="AArgs">
    ///    An array of values to format into the message string.
    ///  </param>
    ///  <remarks>
    ///    Use this method to output custom messages during the lifecycle of the class.
    ///  </remarks>
    procedure Print(const AText: string; const AArgs: array of const);

    ///  <summary>
    ///    Logs a formatted message to the console, appending a newline character at the end.
    ///  </summary>
    procedure PrintLn(const AText: string; const AArgs: array of const);

    ///  <summary>
    ///    Retrieves the most recent error message encountered during operations.
    ///  </summary>
    ///  <returns>
    ///    A string containing the description of the error, or an empty string if no error occurred.
    ///  </returns>
    ///  <remarks>
    ///    This can be used for error reporting or debugging purposes after a failed operation.
    ///  </remarks>
    function GetError(): string;

    ///  <summary>
    ///    Configures the formatting options for text output, including line wrapping
    ///    and maximum line length.
    ///  </summary>
    procedure SetLineOutputInfo(const ARightMargin: Int32; const AMaxLineLength: Int32);

    ///  <summary>
    ///    Retrieves the current text formatting settings for line output.
    ///  </summary>
    procedure GetLineOutputInfo(const ARightMargin: PInt32; const AMaxLineLength: PInt32);


    ///  <summary>
    ///    Retrieves the currently assigned callback that is invoked for each token generated
    ///    during the inference process.
    ///  </summary>
    ///  <returns>
    ///    Returns the callback of type <c>TLumina.NextTokenCallback</c>.
    ///  </returns>
    ///  <remarks>
    ///    The callback function is triggered for every token generated by the model during inference.
    ///    This can be used to process tokens incrementally, enabling real-time handling or streaming
    ///    of the model's output.
    ///  </remarks>
    function GetNextTokenCallback(): TLumina.NextTokenCallback;

    ///  <summary>
    ///    Sets the callback procedure that will be invoked for each token generated during inference.
    ///  </summary>
    ///  <param name="AHandler">
    ///    The callback procedure to handle generated tokens. This must match the
    ///    <c>TLumina.NextTokenCallback</c> type signature.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data that will be passed to the callback.
    ///  </param>
    ///  <remarks>
    ///    Use this method to provide a custom procedure for processing tokens as they are generated
    ///    by the model. This allows applications to handle real-time streaming of output, such as
    ///    displaying text incrementally in a UI or performing intermediate processing.
    ///  </remarks>
    procedure SetNextTokenCallback(const AHandler: TLumina.NextTokenCallback; const AUserData: Pointer);

    ///  <summary>
    ///    Retrieves the currently assigned callback used to cancel the current inference operation.
    ///  </summary>
    ///  <returns>
    ///    Returns the callback of type <c>CancelCallback</c>.
    ///  </returns>
    ///  <remarks>
    ///    The callback function determines whether the inference process should be terminated. If the
    ///    callback returns <c>True</c>, the inference is canceled immediately.
    ///  </remarks>
    function GetCancelCallback(): CancelCallback;

    ///  <summary>
    ///    Sets the callback function that determines whether the current inference operation
    ///    should be canceled.
    ///  </summary>
    ///  <param name="AHandler">
    ///    The callback function that evaluates whether the inference should be terminated.
    ///    This must match the <c>CancelCallback</c> type signature.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data that will be passed to the callback.
    ///  </param>
    ///  <remarks>
    ///    Use this method to provide a mechanism for interrupting inference operations.
    ///    The callback is called periodically during inference, and returning <c>True</c>
    ///    will terminate the operation immediately. This is useful for responding to
    ///    user requests to stop long-running processes.
    ///  </remarks>
    procedure SetCancelCallback(const AHandler: TLumina.CancelCallback; const AUserData: Pointer);

    ///  <summary>
    ///    Retrieves the currently assigned callback that displays the model loading progress.
    ///  </summary>
    ///  <returns>
    ///    Returns the callback of type <c>ProgressCallback</c>.
    ///  </returns>
    ///  <remarks>
    ///    The callback function is invoked during model loading to report progress as a percentage
    ///    from 1% to 100%. This provides real-time feedback on the loading process.
    ///  </remarks>
    function GetProgressCallback(): ProgressCallback;

    ///  <summary>
    ///    Sets the callback procedure that displays the model loading progress.
    ///  </summary>
    ///  <param name="AHandler">
    ///    The callback procedure to handle progress updates. This must match the
    ///    <c>ProgressCallback</c> type signature.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data that will be passed to the callback.
    ///  </param>
    ///  <remarks>
    ///    Use this method to track the loading progress of the model and provide feedback
    ///    to the user, such as updating a progress bar or logging the percentage completed.
    ///  </remarks>
    procedure SetProgressCallback(const AHandler: TLumina.ProgressCallback; const AUserData: Pointer);

    ///  <summary>
    ///    Retrieves the currently assigned callback that displays information about the model
    ///    being loaded.
    ///  </summary>
    ///  <returns>
    ///    Returns the callback of type <c>InfoCallback</c>.
    ///  </returns>
    ///  <remarks>
    ///    The callback function is triggered during model loading to display relevant information,
    ///    such as the model's name, configuration, or status messages.
    ///  </remarks>
    function GetInfoCallback(): InfoCallback;

    ///  <summary>
    ///    Sets the callback procedure that displays information about the model being loaded.
    ///  </summary>
    ///  <param name="AHandler">
    ///    The callback procedure to handle informational messages. This must match the
    ///    <c>InfoCallback</c> type signature.
    ///  </param>
    ///  <param name="AUserData">
    ///    A user-defined pointer to arbitrary data that will be passed to the callback.
    ///  </param>
    ///  <remarks>
    ///    Use this method to log or display details about the model currently being loaded,
    ///    such as its filename, parameters, or other relevant metadata. This can assist in
    ///    debugging and provide users with insights into the operation.
    ///  </remarks>
    procedure SetInfoCallback(const AHandler: TLumina.InfoCallback; const AUserData: Pointer);

    ///  <summary>
    ///    Loads a language model from the specified file and initializes it for inference.
    ///  </summary>
    ///  <remarks>
    ///    Supports both CPU and GPU acceleration, with configurable threading for optimal performance.
    ///  </remarks>
    function  LoadModel(const AModelFilename: string; const ATempate: string=''; const AMaxContext: UInt32=512; const AGPULayers: Int32=-1; const AMaxThreads: Int32=4): Boolean;

    ///  <summary>
    ///    Unloads the currently loaded model, freeing associated resources.
    ///  </summary>
    procedure UnloadModel();

    ///  <summary>
    ///    Runs an inference operation on the currently loaded model, generating tokens
    ///    based on the provided input question.
    ///  </summary>
    ///  <param name="AQuestion">
    ///    The input string (question or prompt) to be processed by the model.
    ///  </param>
    ///  <returns>
    ///    Returns <c>True</c> if the inference operation was successful, or <c>False</c>
    ///    if an error occurred (e.g., no model is loaded or other issues arise).
    ///  </returns>
    ///  <remarks>
    ///    This method processes the given input question using the currently loaded model
    ///    and generates tokens as output. If a <c>NextTokenCallback</c> is assigned, each
    ///    generated token is passed to the callback for processing. If no callback is assigned,
    ///    the tokens are displayed directly to the console.
    ///    <para>
    ///      The method is designed to handle real-time streaming of output by invoking the
    ///      callback incrementally for each token. If the callback is not required, the console
    ///      output provides an alternative mechanism for viewing the generated text.
    ///    </para>
    ///    <para>
    ///      Ensure that a model is loaded before calling this method. If no model is loaded,
    ///      the method will return <c>False</c>, and an error message can be retrieved using
    ///      <c>GetError</c>.
    ///    </para>
    ///  </remarks>
    ///  <example>
    ///    <code lang="Delphi">
    ///    if TLuminaInstance.SimpleInference('What is the capital of France?') then
    ///      Writeln('Inference completed successfully.')
    ///    else
    ///      Writeln('Error: ', TLuminaInstance.GetError());
    ///    </code>
    ///  </example>
    function SimpleInference(const AQuestion: string): Boolean;

    ///  <summary>
    ///    Retrieves the performance metrics of the last inference operation.
    ///  </summary>
    function  GetPerformanceResult(): TLumina.PerformanceResult;
  end;

{$ENDREGION}

implementation

{$REGION ' Lumina.CLibs '}
procedure GetExports(const aDLLHandle: THandle);
begin
  if aDllHandle = 0 then Exit;
  ggml_abort := GetProcAddress(aDLLHandle, 'ggml_abort');
  ggml_abs := GetProcAddress(aDLLHandle, 'ggml_abs');
  ggml_abs_inplace := GetProcAddress(aDLLHandle, 'ggml_abs_inplace');
  ggml_acc := GetProcAddress(aDLLHandle, 'ggml_acc');
  ggml_acc_inplace := GetProcAddress(aDLLHandle, 'ggml_acc_inplace');
  ggml_add := GetProcAddress(aDLLHandle, 'ggml_add');
  ggml_add_cast := GetProcAddress(aDLLHandle, 'ggml_add_cast');
  ggml_add_inplace := GetProcAddress(aDLLHandle, 'ggml_add_inplace');
  ggml_add_rel_pos := GetProcAddress(aDLLHandle, 'ggml_add_rel_pos');
  ggml_add_rel_pos_inplace := GetProcAddress(aDLLHandle, 'ggml_add_rel_pos_inplace');
  ggml_add1 := GetProcAddress(aDLLHandle, 'ggml_add1');
  ggml_add1_inplace := GetProcAddress(aDLLHandle, 'ggml_add1_inplace');
  ggml_arange := GetProcAddress(aDLLHandle, 'ggml_arange');
  ggml_are_same_shape := GetProcAddress(aDLLHandle, 'ggml_are_same_shape');
  ggml_are_same_stride := GetProcAddress(aDLLHandle, 'ggml_are_same_stride');
  ggml_argmax := GetProcAddress(aDLLHandle, 'ggml_argmax');
  ggml_argsort := GetProcAddress(aDLLHandle, 'ggml_argsort');
  ggml_backend_alloc_buffer := GetProcAddress(aDLLHandle, 'ggml_backend_alloc_buffer');
  ggml_backend_alloc_ctx_tensors := GetProcAddress(aDLLHandle, 'ggml_backend_alloc_ctx_tensors');
  ggml_backend_alloc_ctx_tensors_from_buft := GetProcAddress(aDLLHandle, 'ggml_backend_alloc_ctx_tensors_from_buft');
  ggml_backend_buffer_clear := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_clear');
  ggml_backend_buffer_free := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_free');
  ggml_backend_buffer_get_alignment := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_alignment');
  ggml_backend_buffer_get_alloc_size := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_alloc_size');
  ggml_backend_buffer_get_base := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_base');
  ggml_backend_buffer_get_max_size := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_max_size');
  ggml_backend_buffer_get_size := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_size');
  ggml_backend_buffer_get_type := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_type');
  ggml_backend_buffer_get_usage := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_get_usage');
  ggml_backend_buffer_init_tensor := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_init_tensor');
  ggml_backend_buffer_is_host := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_is_host');
  ggml_backend_buffer_name := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_name');
  ggml_backend_buffer_reset := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_reset');
  ggml_backend_buffer_set_usage := GetProcAddress(aDLLHandle, 'ggml_backend_buffer_set_usage');
  ggml_backend_buft_alloc_buffer := GetProcAddress(aDLLHandle, 'ggml_backend_buft_alloc_buffer');
  ggml_backend_buft_get_alignment := GetProcAddress(aDLLHandle, 'ggml_backend_buft_get_alignment');
  ggml_backend_buft_get_alloc_size := GetProcAddress(aDLLHandle, 'ggml_backend_buft_get_alloc_size');
  ggml_backend_buft_get_device := GetProcAddress(aDLLHandle, 'ggml_backend_buft_get_device');
  ggml_backend_buft_get_max_size := GetProcAddress(aDLLHandle, 'ggml_backend_buft_get_max_size');
  ggml_backend_buft_is_host := GetProcAddress(aDLLHandle, 'ggml_backend_buft_is_host');
  ggml_backend_buft_name := GetProcAddress(aDLLHandle, 'ggml_backend_buft_name');
  ggml_backend_compare_graph_backend := GetProcAddress(aDLLHandle, 'ggml_backend_compare_graph_backend');
  ggml_backend_cpu_buffer_from_ptr := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_buffer_from_ptr');
  ggml_backend_cpu_buffer_type := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_buffer_type');
  ggml_backend_cpu_init := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_init');
  ggml_backend_cpu_reg := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_reg');
  ggml_backend_cpu_set_abort_callback := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_set_abort_callback');
  ggml_backend_cpu_set_n_threads := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_set_n_threads');
  ggml_backend_cpu_set_threadpool := GetProcAddress(aDLLHandle, 'ggml_backend_cpu_set_threadpool');
  ggml_backend_dev_backend_reg := GetProcAddress(aDLLHandle, 'ggml_backend_dev_backend_reg');
  ggml_backend_dev_buffer_from_host_ptr := GetProcAddress(aDLLHandle, 'ggml_backend_dev_buffer_from_host_ptr');
  ggml_backend_dev_buffer_type := GetProcAddress(aDLLHandle, 'ggml_backend_dev_buffer_type');
  ggml_backend_dev_by_name := GetProcAddress(aDLLHandle, 'ggml_backend_dev_by_name');
  ggml_backend_dev_by_type := GetProcAddress(aDLLHandle, 'ggml_backend_dev_by_type');
  ggml_backend_dev_count := GetProcAddress(aDLLHandle, 'ggml_backend_dev_count');
  ggml_backend_dev_description := GetProcAddress(aDLLHandle, 'ggml_backend_dev_description');
  ggml_backend_dev_get := GetProcAddress(aDLLHandle, 'ggml_backend_dev_get');
  ggml_backend_dev_get_props := GetProcAddress(aDLLHandle, 'ggml_backend_dev_get_props');
  ggml_backend_dev_host_buffer_type := GetProcAddress(aDLLHandle, 'ggml_backend_dev_host_buffer_type');
  ggml_backend_dev_init := GetProcAddress(aDLLHandle, 'ggml_backend_dev_init');
  ggml_backend_dev_memory := GetProcAddress(aDLLHandle, 'ggml_backend_dev_memory');
  ggml_backend_dev_name := GetProcAddress(aDLLHandle, 'ggml_backend_dev_name');
  ggml_backend_dev_offload_op := GetProcAddress(aDLLHandle, 'ggml_backend_dev_offload_op');
  ggml_backend_dev_supports_buft := GetProcAddress(aDLLHandle, 'ggml_backend_dev_supports_buft');
  ggml_backend_dev_supports_op := GetProcAddress(aDLLHandle, 'ggml_backend_dev_supports_op');
  ggml_backend_dev_type_rtn := GetProcAddress(aDLLHandle, 'ggml_backend_dev_type');
  ggml_backend_event_free := GetProcAddress(aDLLHandle, 'ggml_backend_event_free');
  ggml_backend_event_new := GetProcAddress(aDLLHandle, 'ggml_backend_event_new');
  ggml_backend_event_record := GetProcAddress(aDLLHandle, 'ggml_backend_event_record');
  ggml_backend_event_synchronize := GetProcAddress(aDLLHandle, 'ggml_backend_event_synchronize');
  ggml_backend_event_wait := GetProcAddress(aDLLHandle, 'ggml_backend_event_wait');
  ggml_backend_free := GetProcAddress(aDLLHandle, 'ggml_backend_free');
  ggml_backend_get_alignment := GetProcAddress(aDLLHandle, 'ggml_backend_get_alignment');
  ggml_backend_get_default_buffer_type := GetProcAddress(aDLLHandle, 'ggml_backend_get_default_buffer_type');
  ggml_backend_get_device := GetProcAddress(aDLLHandle, 'ggml_backend_get_device');
  ggml_backend_get_max_size := GetProcAddress(aDLLHandle, 'ggml_backend_get_max_size');
  ggml_backend_graph_compute := GetProcAddress(aDLLHandle, 'ggml_backend_graph_compute');
  ggml_backend_graph_compute_async := GetProcAddress(aDLLHandle, 'ggml_backend_graph_compute_async');
  ggml_backend_graph_copy_free := GetProcAddress(aDLLHandle, 'ggml_backend_graph_copy_free');
  ggml_backend_graph_copy_rtn := GetProcAddress(aDLLHandle, 'ggml_backend_graph_copy');
  ggml_backend_graph_plan_compute := GetProcAddress(aDLLHandle, 'ggml_backend_graph_plan_compute');
  ggml_backend_graph_plan_create := GetProcAddress(aDLLHandle, 'ggml_backend_graph_plan_create');
  ggml_backend_graph_plan_free := GetProcAddress(aDLLHandle, 'ggml_backend_graph_plan_free');
  ggml_backend_guid := GetProcAddress(aDLLHandle, 'ggml_backend_guid');
  ggml_backend_init_best := GetProcAddress(aDLLHandle, 'ggml_backend_init_best');
  ggml_backend_init_by_name := GetProcAddress(aDLLHandle, 'ggml_backend_init_by_name');
  ggml_backend_init_by_type := GetProcAddress(aDLLHandle, 'ggml_backend_init_by_type');
  ggml_backend_is_cpu := GetProcAddress(aDLLHandle, 'ggml_backend_is_cpu');
  ggml_backend_load := GetProcAddress(aDLLHandle, 'ggml_backend_load');
  ggml_backend_load_all := GetProcAddress(aDLLHandle, 'ggml_backend_load_all');
  ggml_backend_load_all_from_path := GetProcAddress(aDLLHandle, 'ggml_backend_load_all_from_path');
  ggml_backend_name := GetProcAddress(aDLLHandle, 'ggml_backend_name');
  ggml_backend_offload_op := GetProcAddress(aDLLHandle, 'ggml_backend_offload_op');
  ggml_backend_reg_by_name := GetProcAddress(aDLLHandle, 'ggml_backend_reg_by_name');
  ggml_backend_reg_count := GetProcAddress(aDLLHandle, 'ggml_backend_reg_count');
  ggml_backend_reg_dev_count := GetProcAddress(aDLLHandle, 'ggml_backend_reg_dev_count');
  ggml_backend_reg_dev_get := GetProcAddress(aDLLHandle, 'ggml_backend_reg_dev_get');
  ggml_backend_reg_get := GetProcAddress(aDLLHandle, 'ggml_backend_reg_get');
  ggml_backend_reg_get_proc_address := GetProcAddress(aDLLHandle, 'ggml_backend_reg_get_proc_address');
  ggml_backend_reg_name := GetProcAddress(aDLLHandle, 'ggml_backend_reg_name');
  ggml_backend_sched_alloc_graph := GetProcAddress(aDLLHandle, 'ggml_backend_sched_alloc_graph');
  ggml_backend_sched_free := GetProcAddress(aDLLHandle, 'ggml_backend_sched_free');
  ggml_backend_sched_get_backend := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_backend');
  ggml_backend_sched_get_buffer_size := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_buffer_size');
  ggml_backend_sched_get_n_backends := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_n_backends');
  ggml_backend_sched_get_n_copies := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_n_copies');
  ggml_backend_sched_get_n_splits := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_n_splits');
  ggml_backend_sched_get_tensor_backend := GetProcAddress(aDLLHandle, 'ggml_backend_sched_get_tensor_backend');
  ggml_backend_sched_graph_compute := GetProcAddress(aDLLHandle, 'ggml_backend_sched_graph_compute');
  ggml_backend_sched_graph_compute_async := GetProcAddress(aDLLHandle, 'ggml_backend_sched_graph_compute_async');
  ggml_backend_sched_new := GetProcAddress(aDLLHandle, 'ggml_backend_sched_new');
  ggml_backend_sched_reserve := GetProcAddress(aDLLHandle, 'ggml_backend_sched_reserve');
  ggml_backend_sched_reset := GetProcAddress(aDLLHandle, 'ggml_backend_sched_reset');
  ggml_backend_sched_set_eval_callback := GetProcAddress(aDLLHandle, 'ggml_backend_sched_set_eval_callback');
  ggml_backend_sched_set_tensor_backend := GetProcAddress(aDLLHandle, 'ggml_backend_sched_set_tensor_backend');
  ggml_backend_sched_synchronize := GetProcAddress(aDLLHandle, 'ggml_backend_sched_synchronize');
  ggml_backend_supports_buft := GetProcAddress(aDLLHandle, 'ggml_backend_supports_buft');
  ggml_backend_supports_op := GetProcAddress(aDLLHandle, 'ggml_backend_supports_op');
  ggml_backend_synchronize := GetProcAddress(aDLLHandle, 'ggml_backend_synchronize');
  ggml_backend_tensor_alloc := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_alloc');
  ggml_backend_tensor_copy := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_copy');
  ggml_backend_tensor_copy_async := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_copy_async');
  ggml_backend_tensor_get := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_get');
  ggml_backend_tensor_get_async := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_get_async');
  ggml_backend_tensor_memset := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_memset');
  ggml_backend_tensor_set := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_set');
  ggml_backend_tensor_set_async := GetProcAddress(aDLLHandle, 'ggml_backend_tensor_set_async');
  ggml_backend_unload := GetProcAddress(aDLLHandle, 'ggml_backend_unload');
  ggml_backend_view_init := GetProcAddress(aDLLHandle, 'ggml_backend_view_init');
  ggml_bf16_to_fp32 := GetProcAddress(aDLLHandle, 'ggml_bf16_to_fp32');
  ggml_bf16_to_fp32_row := GetProcAddress(aDLLHandle, 'ggml_bf16_to_fp32_row');
  ggml_blck_size := GetProcAddress(aDLLHandle, 'ggml_blck_size');
  ggml_build_backward_expand := GetProcAddress(aDLLHandle, 'ggml_build_backward_expand');
  ggml_build_forward_expand := GetProcAddress(aDLLHandle, 'ggml_build_forward_expand');
  ggml_can_repeat := GetProcAddress(aDLLHandle, 'ggml_can_repeat');
  ggml_cast := GetProcAddress(aDLLHandle, 'ggml_cast');
  ggml_clamp := GetProcAddress(aDLLHandle, 'ggml_clamp');
  ggml_concat := GetProcAddress(aDLLHandle, 'ggml_concat');
  ggml_cont := GetProcAddress(aDLLHandle, 'ggml_cont');
  ggml_cont_1d := GetProcAddress(aDLLHandle, 'ggml_cont_1d');
  ggml_cont_2d := GetProcAddress(aDLLHandle, 'ggml_cont_2d');
  ggml_cont_3d := GetProcAddress(aDLLHandle, 'ggml_cont_3d');
  ggml_cont_4d := GetProcAddress(aDLLHandle, 'ggml_cont_4d');
  ggml_conv_1d := GetProcAddress(aDLLHandle, 'ggml_conv_1d');
  ggml_conv_1d_dw := GetProcAddress(aDLLHandle, 'ggml_conv_1d_dw');
  ggml_conv_1d_dw_ph := GetProcAddress(aDLLHandle, 'ggml_conv_1d_dw_ph');
  ggml_conv_1d_ph := GetProcAddress(aDLLHandle, 'ggml_conv_1d_ph');
  ggml_conv_2d := GetProcAddress(aDLLHandle, 'ggml_conv_2d');
  ggml_conv_2d_dw := GetProcAddress(aDLLHandle, 'ggml_conv_2d_dw');
  ggml_conv_2d_s1_ph := GetProcAddress(aDLLHandle, 'ggml_conv_2d_s1_ph');
  ggml_conv_2d_sk_p0 := GetProcAddress(aDLLHandle, 'ggml_conv_2d_sk_p0');
  ggml_conv_transpose_1d := GetProcAddress(aDLLHandle, 'ggml_conv_transpose_1d');
  ggml_conv_transpose_2d_p0 := GetProcAddress(aDLLHandle, 'ggml_conv_transpose_2d_p0');
  ggml_cos := GetProcAddress(aDLLHandle, 'ggml_cos');
  ggml_cos_inplace := GetProcAddress(aDLLHandle, 'ggml_cos_inplace');
  ggml_count_equal := GetProcAddress(aDLLHandle, 'ggml_count_equal');
  ggml_cpu_get_sve_cnt := GetProcAddress(aDLLHandle, 'ggml_cpu_get_sve_cnt');
  ggml_cpu_has_amx_int8 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_amx_int8');
  ggml_cpu_has_arm_fma := GetProcAddress(aDLLHandle, 'ggml_cpu_has_arm_fma');
  ggml_cpu_has_avx := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx');
  ggml_cpu_has_avx_vnni := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx_vnni');
  ggml_cpu_has_avx2 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx2');
  ggml_cpu_has_avx512 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx512');
  ggml_cpu_has_avx512_bf16 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx512_bf16');
  ggml_cpu_has_avx512_vbmi := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx512_vbmi');
  ggml_cpu_has_avx512_vnni := GetProcAddress(aDLLHandle, 'ggml_cpu_has_avx512_vnni');
  ggml_cpu_has_dotprod := GetProcAddress(aDLLHandle, 'ggml_cpu_has_dotprod');
  ggml_cpu_has_f16c := GetProcAddress(aDLLHandle, 'ggml_cpu_has_f16c');
  ggml_cpu_has_fma := GetProcAddress(aDLLHandle, 'ggml_cpu_has_fma');
  ggml_cpu_has_fp16_va := GetProcAddress(aDLLHandle, 'ggml_cpu_has_fp16_va');
  ggml_cpu_has_llamafile := GetProcAddress(aDLLHandle, 'ggml_cpu_has_llamafile');
  ggml_cpu_has_matmul_int8 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_matmul_int8');
  ggml_cpu_has_neon := GetProcAddress(aDLLHandle, 'ggml_cpu_has_neon');
  ggml_cpu_has_riscv_v := GetProcAddress(aDLLHandle, 'ggml_cpu_has_riscv_v');
  ggml_cpu_has_sse3 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_sse3');
  ggml_cpu_has_ssse3 := GetProcAddress(aDLLHandle, 'ggml_cpu_has_ssse3');
  ggml_cpu_has_sve := GetProcAddress(aDLLHandle, 'ggml_cpu_has_sve');
  ggml_cpu_has_vsx := GetProcAddress(aDLLHandle, 'ggml_cpu_has_vsx');
  ggml_cpu_has_wasm_simd := GetProcAddress(aDLLHandle, 'ggml_cpu_has_wasm_simd');
  ggml_cpu_init := GetProcAddress(aDLLHandle, 'ggml_cpu_init');
  ggml_cpy := GetProcAddress(aDLLHandle, 'ggml_cpy');
  ggml_cross_entropy_loss := GetProcAddress(aDLLHandle, 'ggml_cross_entropy_loss');
  ggml_cross_entropy_loss_back := GetProcAddress(aDLLHandle, 'ggml_cross_entropy_loss_back');
  ggml_cycles := GetProcAddress(aDLLHandle, 'ggml_cycles');
  ggml_cycles_per_ms := GetProcAddress(aDLLHandle, 'ggml_cycles_per_ms');
  ggml_diag := GetProcAddress(aDLLHandle, 'ggml_diag');
  ggml_diag_mask_inf := GetProcAddress(aDLLHandle, 'ggml_diag_mask_inf');
  ggml_diag_mask_inf_inplace := GetProcAddress(aDLLHandle, 'ggml_diag_mask_inf_inplace');
  ggml_diag_mask_zero := GetProcAddress(aDLLHandle, 'ggml_diag_mask_zero');
  ggml_diag_mask_zero_inplace := GetProcAddress(aDLLHandle, 'ggml_diag_mask_zero_inplace');
  ggml_div := GetProcAddress(aDLLHandle, 'ggml_div');
  ggml_div_inplace := GetProcAddress(aDLLHandle, 'ggml_div_inplace');
  ggml_dup := GetProcAddress(aDLLHandle, 'ggml_dup');
  ggml_dup_inplace := GetProcAddress(aDLLHandle, 'ggml_dup_inplace');
  ggml_dup_tensor := GetProcAddress(aDLLHandle, 'ggml_dup_tensor');
  ggml_element_size := GetProcAddress(aDLLHandle, 'ggml_element_size');
  ggml_elu := GetProcAddress(aDLLHandle, 'ggml_elu');
  ggml_elu_inplace := GetProcAddress(aDLLHandle, 'ggml_elu_inplace');
  ggml_exp := GetProcAddress(aDLLHandle, 'ggml_exp');
  ggml_exp_inplace := GetProcAddress(aDLLHandle, 'ggml_exp_inplace');
  ggml_flash_attn_back := GetProcAddress(aDLLHandle, 'ggml_flash_attn_back');
  ggml_flash_attn_ext := GetProcAddress(aDLLHandle, 'ggml_flash_attn_ext');
  ggml_flash_attn_ext_get_prec := GetProcAddress(aDLLHandle, 'ggml_flash_attn_ext_get_prec');
  ggml_flash_attn_ext_set_prec := GetProcAddress(aDLLHandle, 'ggml_flash_attn_ext_set_prec');
  ggml_fopen := GetProcAddress(aDLLHandle, 'ggml_fopen');
  ggml_format_name := GetProcAddress(aDLLHandle, 'ggml_format_name');
  ggml_fp16_to_fp32 := GetProcAddress(aDLLHandle, 'ggml_fp16_to_fp32');
  ggml_fp16_to_fp32_row := GetProcAddress(aDLLHandle, 'ggml_fp16_to_fp32_row');
  ggml_fp32_to_bf16 := GetProcAddress(aDLLHandle, 'ggml_fp32_to_bf16');
  ggml_fp32_to_bf16_row := GetProcAddress(aDLLHandle, 'ggml_fp32_to_bf16_row');
  ggml_fp32_to_bf16_row_ref := GetProcAddress(aDLLHandle, 'ggml_fp32_to_bf16_row_ref');
  ggml_fp32_to_fp16 := GetProcAddress(aDLLHandle, 'ggml_fp32_to_fp16');
  ggml_fp32_to_fp16_row := GetProcAddress(aDLLHandle, 'ggml_fp32_to_fp16_row');
  ggml_free := GetProcAddress(aDLLHandle, 'ggml_free');
  ggml_ftype_to_ggml_type := GetProcAddress(aDLLHandle, 'ggml_ftype_to_ggml_type');
  ggml_gallocr_alloc_graph := GetProcAddress(aDLLHandle, 'ggml_gallocr_alloc_graph');
  ggml_gallocr_free := GetProcAddress(aDLLHandle, 'ggml_gallocr_free');
  ggml_gallocr_get_buffer_size := GetProcAddress(aDLLHandle, 'ggml_gallocr_get_buffer_size');
  ggml_gallocr_new := GetProcAddress(aDLLHandle, 'ggml_gallocr_new');
  ggml_gallocr_new_n := GetProcAddress(aDLLHandle, 'ggml_gallocr_new_n');
  ggml_gallocr_reserve := GetProcAddress(aDLLHandle, 'ggml_gallocr_reserve');
  ggml_gallocr_reserve_n := GetProcAddress(aDLLHandle, 'ggml_gallocr_reserve_n');
  ggml_gelu := GetProcAddress(aDLLHandle, 'ggml_gelu');
  ggml_gelu_inplace := GetProcAddress(aDLLHandle, 'ggml_gelu_inplace');
  ggml_gelu_quick := GetProcAddress(aDLLHandle, 'ggml_gelu_quick');
  ggml_gelu_quick_inplace := GetProcAddress(aDLLHandle, 'ggml_gelu_quick_inplace');
  ggml_get_data := GetProcAddress(aDLLHandle, 'ggml_get_data');
  ggml_get_data_f32 := GetProcAddress(aDLLHandle, 'ggml_get_data_f32');
  ggml_get_f32_1d := GetProcAddress(aDLLHandle, 'ggml_get_f32_1d');
  ggml_get_f32_nd := GetProcAddress(aDLLHandle, 'ggml_get_f32_nd');
  ggml_get_first_tensor := GetProcAddress(aDLLHandle, 'ggml_get_first_tensor');
  ggml_get_i32_1d := GetProcAddress(aDLLHandle, 'ggml_get_i32_1d');
  ggml_get_i32_nd := GetProcAddress(aDLLHandle, 'ggml_get_i32_nd');
  ggml_get_max_tensor_size := GetProcAddress(aDLLHandle, 'ggml_get_max_tensor_size');
  ggml_get_mem_buffer := GetProcAddress(aDLLHandle, 'ggml_get_mem_buffer');
  ggml_get_mem_size := GetProcAddress(aDLLHandle, 'ggml_get_mem_size');
  ggml_get_name := GetProcAddress(aDLLHandle, 'ggml_get_name');
  ggml_get_next_tensor := GetProcAddress(aDLLHandle, 'ggml_get_next_tensor');
  ggml_get_no_alloc := GetProcAddress(aDLLHandle, 'ggml_get_no_alloc');
  ggml_get_rel_pos := GetProcAddress(aDLLHandle, 'ggml_get_rel_pos');
  ggml_get_rows := GetProcAddress(aDLLHandle, 'ggml_get_rows');
  ggml_get_rows_back := GetProcAddress(aDLLHandle, 'ggml_get_rows_back');
  ggml_get_tensor := GetProcAddress(aDLLHandle, 'ggml_get_tensor');
  ggml_get_type_traits := GetProcAddress(aDLLHandle, 'ggml_get_type_traits');
  ggml_get_type_traits_cpu := GetProcAddress(aDLLHandle, 'ggml_get_type_traits_cpu');
  ggml_get_unary_op := GetProcAddress(aDLLHandle, 'ggml_get_unary_op');
  ggml_graph_add_node := GetProcAddress(aDLLHandle, 'ggml_graph_add_node');
  ggml_graph_clear := GetProcAddress(aDLLHandle, 'ggml_graph_clear');
  ggml_graph_compute := GetProcAddress(aDLLHandle, 'ggml_graph_compute');
  ggml_graph_compute_with_ctx := GetProcAddress(aDLLHandle, 'ggml_graph_compute_with_ctx');
  ggml_graph_cpy := GetProcAddress(aDLLHandle, 'ggml_graph_cpy');
  ggml_graph_dump_dot := GetProcAddress(aDLLHandle, 'ggml_graph_dump_dot');
  ggml_graph_dup := GetProcAddress(aDLLHandle, 'ggml_graph_dup');
  ggml_graph_get_grad := GetProcAddress(aDLLHandle, 'ggml_graph_get_grad');
  ggml_graph_get_grad_acc := GetProcAddress(aDLLHandle, 'ggml_graph_get_grad_acc');
  ggml_graph_get_tensor := GetProcAddress(aDLLHandle, 'ggml_graph_get_tensor');
  ggml_graph_n_nodes := GetProcAddress(aDLLHandle, 'ggml_graph_n_nodes');
  ggml_graph_node := GetProcAddress(aDLLHandle, 'ggml_graph_node');
  ggml_graph_nodes := GetProcAddress(aDLLHandle, 'ggml_graph_nodes');
  ggml_graph_overhead := GetProcAddress(aDLLHandle, 'ggml_graph_overhead');
  ggml_graph_overhead_custom := GetProcAddress(aDLLHandle, 'ggml_graph_overhead_custom');
  ggml_graph_plan := GetProcAddress(aDLLHandle, 'ggml_graph_plan');
  ggml_graph_print := GetProcAddress(aDLLHandle, 'ggml_graph_print');
  ggml_graph_reset := GetProcAddress(aDLLHandle, 'ggml_graph_reset');
  ggml_graph_size := GetProcAddress(aDLLHandle, 'ggml_graph_size');
  ggml_group_norm := GetProcAddress(aDLLHandle, 'ggml_group_norm');
  ggml_group_norm_inplace := GetProcAddress(aDLLHandle, 'ggml_group_norm_inplace');
  ggml_guid_matches := GetProcAddress(aDLLHandle, 'ggml_guid_matches');
  ggml_hardsigmoid := GetProcAddress(aDLLHandle, 'ggml_hardsigmoid');
  ggml_hardswish := GetProcAddress(aDLLHandle, 'ggml_hardswish');
  ggml_im2col := GetProcAddress(aDLLHandle, 'ggml_im2col');
  ggml_im2col_back := GetProcAddress(aDLLHandle, 'ggml_im2col_back');
  ggml_init := GetProcAddress(aDLLHandle, 'ggml_init');
  ggml_is_3d := GetProcAddress(aDLLHandle, 'ggml_is_3d');
  ggml_is_contiguous := GetProcAddress(aDLLHandle, 'ggml_is_contiguous');
  ggml_is_contiguous_0 := GetProcAddress(aDLLHandle, 'ggml_is_contiguous_0');
  ggml_is_contiguous_1 := GetProcAddress(aDLLHandle, 'ggml_is_contiguous_1');
  ggml_is_contiguous_2 := GetProcAddress(aDLLHandle, 'ggml_is_contiguous_2');
  ggml_is_empty := GetProcAddress(aDLLHandle, 'ggml_is_empty');
  ggml_is_matrix := GetProcAddress(aDLLHandle, 'ggml_is_matrix');
  ggml_is_numa := GetProcAddress(aDLLHandle, 'ggml_is_numa');
  ggml_is_permuted := GetProcAddress(aDLLHandle, 'ggml_is_permuted');
  ggml_is_quantized := GetProcAddress(aDLLHandle, 'ggml_is_quantized');
  ggml_is_scalar := GetProcAddress(aDLLHandle, 'ggml_is_scalar');
  ggml_is_transposed := GetProcAddress(aDLLHandle, 'ggml_is_transposed');
  ggml_is_vector := GetProcAddress(aDLLHandle, 'ggml_is_vector');
  ggml_leaky_relu := GetProcAddress(aDLLHandle, 'ggml_leaky_relu');
  ggml_log := GetProcAddress(aDLLHandle, 'ggml_log');
  ggml_log_inplace := GetProcAddress(aDLLHandle, 'ggml_log_inplace');
  ggml_log_set := GetProcAddress(aDLLHandle, 'ggml_log_set');
  ggml_map_binary_f32 := GetProcAddress(aDLLHandle, 'ggml_map_binary_f32');
  ggml_map_binary_inplace_f32 := GetProcAddress(aDLLHandle, 'ggml_map_binary_inplace_f32');
  ggml_map_custom1 := GetProcAddress(aDLLHandle, 'ggml_map_custom1');
  ggml_map_custom1_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom1_f32');
  ggml_map_custom1_inplace := GetProcAddress(aDLLHandle, 'ggml_map_custom1_inplace');
  ggml_map_custom1_inplace_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom1_inplace_f32');
  ggml_map_custom2 := GetProcAddress(aDLLHandle, 'ggml_map_custom2');
  ggml_map_custom2_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom2_f32');
  ggml_map_custom2_inplace := GetProcAddress(aDLLHandle, 'ggml_map_custom2_inplace');
  ggml_map_custom2_inplace_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom2_inplace_f32');
  ggml_map_custom3 := GetProcAddress(aDLLHandle, 'ggml_map_custom3');
  ggml_map_custom3_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom3_f32');
  ggml_map_custom3_inplace := GetProcAddress(aDLLHandle, 'ggml_map_custom3_inplace');
  ggml_map_custom3_inplace_f32 := GetProcAddress(aDLLHandle, 'ggml_map_custom3_inplace_f32');
  ggml_map_unary_f32 := GetProcAddress(aDLLHandle, 'ggml_map_unary_f32');
  ggml_map_unary_inplace_f32 := GetProcAddress(aDLLHandle, 'ggml_map_unary_inplace_f32');
  ggml_mean := GetProcAddress(aDLLHandle, 'ggml_mean');
  ggml_mul := GetProcAddress(aDLLHandle, 'ggml_mul');
  ggml_mul_inplace := GetProcAddress(aDLLHandle, 'ggml_mul_inplace');
  ggml_mul_mat := GetProcAddress(aDLLHandle, 'ggml_mul_mat');
  ggml_mul_mat_id := GetProcAddress(aDLLHandle, 'ggml_mul_mat_id');
  ggml_mul_mat_set_prec := GetProcAddress(aDLLHandle, 'ggml_mul_mat_set_prec');
  ggml_n_dims := GetProcAddress(aDLLHandle, 'ggml_n_dims');
  ggml_nbytes := GetProcAddress(aDLLHandle, 'ggml_nbytes');
  ggml_nbytes_pad := GetProcAddress(aDLLHandle, 'ggml_nbytes_pad');
  ggml_neg := GetProcAddress(aDLLHandle, 'ggml_neg');
  ggml_neg_inplace := GetProcAddress(aDLLHandle, 'ggml_neg_inplace');
  ggml_nelements := GetProcAddress(aDLLHandle, 'ggml_nelements');
  ggml_new_buffer := GetProcAddress(aDLLHandle, 'ggml_new_buffer');
  ggml_new_f32 := GetProcAddress(aDLLHandle, 'ggml_new_f32');
  ggml_new_graph := GetProcAddress(aDLLHandle, 'ggml_new_graph');
  ggml_new_graph_custom := GetProcAddress(aDLLHandle, 'ggml_new_graph_custom');
  ggml_new_i32 := GetProcAddress(aDLLHandle, 'ggml_new_i32');
  ggml_new_tensor := GetProcAddress(aDLLHandle, 'ggml_new_tensor');
  ggml_new_tensor_1d := GetProcAddress(aDLLHandle, 'ggml_new_tensor_1d');
  ggml_new_tensor_2d := GetProcAddress(aDLLHandle, 'ggml_new_tensor_2d');
  ggml_new_tensor_3d := GetProcAddress(aDLLHandle, 'ggml_new_tensor_3d');
  ggml_new_tensor_4d := GetProcAddress(aDLLHandle, 'ggml_new_tensor_4d');
  ggml_norm := GetProcAddress(aDLLHandle, 'ggml_norm');
  ggml_norm_inplace := GetProcAddress(aDLLHandle, 'ggml_norm_inplace');
  ggml_nrows := GetProcAddress(aDLLHandle, 'ggml_nrows');
  ggml_numa_init := GetProcAddress(aDLLHandle, 'ggml_numa_init');
  ggml_op_desc := GetProcAddress(aDLLHandle, 'ggml_op_desc');
  ggml_op_name := GetProcAddress(aDLLHandle, 'ggml_op_name');
  ggml_op_symbol := GetProcAddress(aDLLHandle, 'ggml_op_symbol');
  ggml_opt_step_adamw := GetProcAddress(aDLLHandle, 'ggml_opt_step_adamw');
  ggml_out_prod := GetProcAddress(aDLLHandle, 'ggml_out_prod');
  ggml_pad := GetProcAddress(aDLLHandle, 'ggml_pad');
  ggml_pad_reflect_1d := GetProcAddress(aDLLHandle, 'ggml_pad_reflect_1d');
  ggml_permute := GetProcAddress(aDLLHandle, 'ggml_permute');
  ggml_pool_1d := GetProcAddress(aDLLHandle, 'ggml_pool_1d');
  ggml_pool_2d := GetProcAddress(aDLLHandle, 'ggml_pool_2d');
  ggml_pool_2d_back := GetProcAddress(aDLLHandle, 'ggml_pool_2d_back');
  ggml_print_object := GetProcAddress(aDLLHandle, 'ggml_print_object');
  ggml_print_objects := GetProcAddress(aDLLHandle, 'ggml_print_objects');
  ggml_quantize_chunk := GetProcAddress(aDLLHandle, 'ggml_quantize_chunk');
  ggml_quantize_free := GetProcAddress(aDLLHandle, 'ggml_quantize_free');
  ggml_quantize_init := GetProcAddress(aDLLHandle, 'ggml_quantize_init');
  ggml_quantize_requires_imatrix := GetProcAddress(aDLLHandle, 'ggml_quantize_requires_imatrix');
  ggml_relu := GetProcAddress(aDLLHandle, 'ggml_relu');
  ggml_relu_inplace := GetProcAddress(aDLLHandle, 'ggml_relu_inplace');
  ggml_repeat := GetProcAddress(aDLLHandle, 'ggml_repeat');
  ggml_repeat_back := GetProcAddress(aDLLHandle, 'ggml_repeat_back');
  ggml_reset := GetProcAddress(aDLLHandle, 'ggml_reset');
  ggml_reshape := GetProcAddress(aDLLHandle, 'ggml_reshape');
  ggml_reshape_1d := GetProcAddress(aDLLHandle, 'ggml_reshape_1d');
  ggml_reshape_2d := GetProcAddress(aDLLHandle, 'ggml_reshape_2d');
  ggml_reshape_3d := GetProcAddress(aDLLHandle, 'ggml_reshape_3d');
  ggml_reshape_4d := GetProcAddress(aDLLHandle, 'ggml_reshape_4d');
  ggml_rms_norm := GetProcAddress(aDLLHandle, 'ggml_rms_norm');
  ggml_rms_norm_back := GetProcAddress(aDLLHandle, 'ggml_rms_norm_back');
  ggml_rms_norm_inplace := GetProcAddress(aDLLHandle, 'ggml_rms_norm_inplace');
  ggml_rope := GetProcAddress(aDLLHandle, 'ggml_rope');
  ggml_rope_back := GetProcAddress(aDLLHandle, 'ggml_rope_back');
  ggml_rope_custom := GetProcAddress(aDLLHandle, 'ggml_rope_custom');
  ggml_rope_custom_inplace := GetProcAddress(aDLLHandle, 'ggml_rope_custom_inplace');
  ggml_rope_ext := GetProcAddress(aDLLHandle, 'ggml_rope_ext');
  ggml_rope_ext_inplace := GetProcAddress(aDLLHandle, 'ggml_rope_ext_inplace');
  ggml_rope_inplace := GetProcAddress(aDLLHandle, 'ggml_rope_inplace');
  ggml_rope_multi := GetProcAddress(aDLLHandle, 'ggml_rope_multi');
  ggml_rope_yarn_corr_dims := GetProcAddress(aDLLHandle, 'ggml_rope_yarn_corr_dims');
  ggml_row_size := GetProcAddress(aDLLHandle, 'ggml_row_size');
  ggml_rwkv_wkv6 := GetProcAddress(aDLLHandle, 'ggml_rwkv_wkv6');
  ggml_scale := GetProcAddress(aDLLHandle, 'ggml_scale');
  ggml_scale_inplace := GetProcAddress(aDLLHandle, 'ggml_scale_inplace');
  ggml_set := GetProcAddress(aDLLHandle, 'ggml_set');
  ggml_set_1d := GetProcAddress(aDLLHandle, 'ggml_set_1d');
  ggml_set_1d_inplace := GetProcAddress(aDLLHandle, 'ggml_set_1d_inplace');
  ggml_set_2d := GetProcAddress(aDLLHandle, 'ggml_set_2d');
  ggml_set_2d_inplace := GetProcAddress(aDLLHandle, 'ggml_set_2d_inplace');
  ggml_set_f32 := GetProcAddress(aDLLHandle, 'ggml_set_f32');
  ggml_set_f32_1d := GetProcAddress(aDLLHandle, 'ggml_set_f32_1d');
  ggml_set_f32_nd := GetProcAddress(aDLLHandle, 'ggml_set_f32_nd');
  ggml_set_i32 := GetProcAddress(aDLLHandle, 'ggml_set_i32');
  ggml_set_i32_1d := GetProcAddress(aDLLHandle, 'ggml_set_i32_1d');
  ggml_set_i32_nd := GetProcAddress(aDLLHandle, 'ggml_set_i32_nd');
  ggml_set_inplace := GetProcAddress(aDLLHandle, 'ggml_set_inplace');
  ggml_set_input := GetProcAddress(aDLLHandle, 'ggml_set_input');
  ggml_set_loss := GetProcAddress(aDLLHandle, 'ggml_set_loss');
  ggml_set_name := GetProcAddress(aDLLHandle, 'ggml_set_name');
  ggml_set_no_alloc := GetProcAddress(aDLLHandle, 'ggml_set_no_alloc');
  ggml_set_output := GetProcAddress(aDLLHandle, 'ggml_set_output');
  ggml_set_param := GetProcAddress(aDLLHandle, 'ggml_set_param');
  ggml_set_zero := GetProcAddress(aDLLHandle, 'ggml_set_zero');
  ggml_sgn := GetProcAddress(aDLLHandle, 'ggml_sgn');
  ggml_sgn_inplace := GetProcAddress(aDLLHandle, 'ggml_sgn_inplace');
  ggml_sigmoid := GetProcAddress(aDLLHandle, 'ggml_sigmoid');
  ggml_sigmoid_inplace := GetProcAddress(aDLLHandle, 'ggml_sigmoid_inplace');
  ggml_silu := GetProcAddress(aDLLHandle, 'ggml_silu');
  ggml_silu_back := GetProcAddress(aDLLHandle, 'ggml_silu_back');
  ggml_silu_inplace := GetProcAddress(aDLLHandle, 'ggml_silu_inplace');
  ggml_sin := GetProcAddress(aDLLHandle, 'ggml_sin');
  ggml_sin_inplace := GetProcAddress(aDLLHandle, 'ggml_sin_inplace');
  ggml_soft_max := GetProcAddress(aDLLHandle, 'ggml_soft_max');
  ggml_soft_max_back := GetProcAddress(aDLLHandle, 'ggml_soft_max_back');
  ggml_soft_max_back_inplace := GetProcAddress(aDLLHandle, 'ggml_soft_max_back_inplace');
  ggml_soft_max_ext := GetProcAddress(aDLLHandle, 'ggml_soft_max_ext');
  ggml_soft_max_inplace := GetProcAddress(aDLLHandle, 'ggml_soft_max_inplace');
  ggml_sqr := GetProcAddress(aDLLHandle, 'ggml_sqr');
  ggml_sqr_inplace := GetProcAddress(aDLLHandle, 'ggml_sqr_inplace');
  ggml_sqrt := GetProcAddress(aDLLHandle, 'ggml_sqrt');
  ggml_sqrt_inplace := GetProcAddress(aDLLHandle, 'ggml_sqrt_inplace');
  ggml_ssm_conv := GetProcAddress(aDLLHandle, 'ggml_ssm_conv');
  ggml_ssm_scan := GetProcAddress(aDLLHandle, 'ggml_ssm_scan');
  ggml_status_to_string := GetProcAddress(aDLLHandle, 'ggml_status_to_string');
  ggml_step := GetProcAddress(aDLLHandle, 'ggml_step');
  ggml_step_inplace := GetProcAddress(aDLLHandle, 'ggml_step_inplace');
  ggml_sub := GetProcAddress(aDLLHandle, 'ggml_sub');
  ggml_sub_inplace := GetProcAddress(aDLLHandle, 'ggml_sub_inplace');
  ggml_sum := GetProcAddress(aDLLHandle, 'ggml_sum');
  ggml_sum_rows := GetProcAddress(aDLLHandle, 'ggml_sum_rows');
  ggml_tallocr_alloc := GetProcAddress(aDLLHandle, 'ggml_tallocr_alloc');
  ggml_tallocr_new := GetProcAddress(aDLLHandle, 'ggml_tallocr_new');
  ggml_tanh := GetProcAddress(aDLLHandle, 'ggml_tanh');
  ggml_tanh_inplace := GetProcAddress(aDLLHandle, 'ggml_tanh_inplace');
  ggml_tensor_overhead := GetProcAddress(aDLLHandle, 'ggml_tensor_overhead');
  ggml_threadpool_free := GetProcAddress(aDLLHandle, 'ggml_threadpool_free');
  ggml_threadpool_new := GetProcAddress(aDLLHandle, 'ggml_threadpool_new');
  ggml_threadpool_params_default := GetProcAddress(aDLLHandle, 'ggml_threadpool_params_default');
  ggml_threadpool_params_init := GetProcAddress(aDLLHandle, 'ggml_threadpool_params_init');
  ggml_threadpool_params_match := GetProcAddress(aDLLHandle, 'ggml_threadpool_params_match');
  ggml_threadpool_pause := GetProcAddress(aDLLHandle, 'ggml_threadpool_pause');
  ggml_threadpool_resume := GetProcAddress(aDLLHandle, 'ggml_threadpool_resume');
  ggml_time_init := GetProcAddress(aDLLHandle, 'ggml_time_init');
  ggml_time_ms := GetProcAddress(aDLLHandle, 'ggml_time_ms');
  ggml_time_us := GetProcAddress(aDLLHandle, 'ggml_time_us');
  ggml_timestep_embedding := GetProcAddress(aDLLHandle, 'ggml_timestep_embedding');
  ggml_top_k := GetProcAddress(aDLLHandle, 'ggml_top_k');
  ggml_transpose := GetProcAddress(aDLLHandle, 'ggml_transpose');
  ggml_type_name := GetProcAddress(aDLLHandle, 'ggml_type_name');
  ggml_type_size := GetProcAddress(aDLLHandle, 'ggml_type_size');
  ggml_type_sizef := GetProcAddress(aDLLHandle, 'ggml_type_sizef');
  ggml_unary := GetProcAddress(aDLLHandle, 'ggml_unary');
  ggml_unary_inplace := GetProcAddress(aDLLHandle, 'ggml_unary_inplace');
  ggml_unary_op_name := GetProcAddress(aDLLHandle, 'ggml_unary_op_name');
  ggml_unravel_index := GetProcAddress(aDLLHandle, 'ggml_unravel_index');
  ggml_upscale := GetProcAddress(aDLLHandle, 'ggml_upscale');
  ggml_upscale_ext := GetProcAddress(aDLLHandle, 'ggml_upscale_ext');
  ggml_used_mem := GetProcAddress(aDLLHandle, 'ggml_used_mem');
  ggml_validate_row_data := GetProcAddress(aDLLHandle, 'ggml_validate_row_data');
  ggml_view_1d := GetProcAddress(aDLLHandle, 'ggml_view_1d');
  ggml_view_2d := GetProcAddress(aDLLHandle, 'ggml_view_2d');
  ggml_view_3d := GetProcAddress(aDLLHandle, 'ggml_view_3d');
  ggml_view_4d := GetProcAddress(aDLLHandle, 'ggml_view_4d');
  ggml_view_tensor := GetProcAddress(aDLLHandle, 'ggml_view_tensor');
  ggml_win_part := GetProcAddress(aDLLHandle, 'ggml_win_part');
  ggml_win_unpart := GetProcAddress(aDLLHandle, 'ggml_win_unpart');
  gguf_add_tensor := GetProcAddress(aDLLHandle, 'gguf_add_tensor');
  gguf_find_key := GetProcAddress(aDLLHandle, 'gguf_find_key');
  gguf_find_tensor := GetProcAddress(aDLLHandle, 'gguf_find_tensor');
  gguf_free := GetProcAddress(aDLLHandle, 'gguf_free');
  gguf_get_alignment := GetProcAddress(aDLLHandle, 'gguf_get_alignment');
  gguf_get_arr_data := GetProcAddress(aDLLHandle, 'gguf_get_arr_data');
  gguf_get_arr_n := GetProcAddress(aDLLHandle, 'gguf_get_arr_n');
  gguf_get_arr_str := GetProcAddress(aDLLHandle, 'gguf_get_arr_str');
  gguf_get_arr_type := GetProcAddress(aDLLHandle, 'gguf_get_arr_type');
  gguf_get_data := GetProcAddress(aDLLHandle, 'gguf_get_data');
  gguf_get_data_offset := GetProcAddress(aDLLHandle, 'gguf_get_data_offset');
  gguf_get_key := GetProcAddress(aDLLHandle, 'gguf_get_key');
  gguf_get_kv_type := GetProcAddress(aDLLHandle, 'gguf_get_kv_type');
  gguf_get_meta_data := GetProcAddress(aDLLHandle, 'gguf_get_meta_data');
  gguf_get_meta_size := GetProcAddress(aDLLHandle, 'gguf_get_meta_size');
  gguf_get_n_kv := GetProcAddress(aDLLHandle, 'gguf_get_n_kv');
  gguf_get_n_tensors := GetProcAddress(aDLLHandle, 'gguf_get_n_tensors');
  gguf_get_tensor_name := GetProcAddress(aDLLHandle, 'gguf_get_tensor_name');
  gguf_get_tensor_offset := GetProcAddress(aDLLHandle, 'gguf_get_tensor_offset');
  gguf_get_tensor_type := GetProcAddress(aDLLHandle, 'gguf_get_tensor_type');
  gguf_get_val_bool := GetProcAddress(aDLLHandle, 'gguf_get_val_bool');
  gguf_get_val_data := GetProcAddress(aDLLHandle, 'gguf_get_val_data');
  gguf_get_val_f32 := GetProcAddress(aDLLHandle, 'gguf_get_val_f32');
  gguf_get_val_f64 := GetProcAddress(aDLLHandle, 'gguf_get_val_f64');
  gguf_get_val_i16 := GetProcAddress(aDLLHandle, 'gguf_get_val_i16');
  gguf_get_val_i32 := GetProcAddress(aDLLHandle, 'gguf_get_val_i32');
  gguf_get_val_i64 := GetProcAddress(aDLLHandle, 'gguf_get_val_i64');
  gguf_get_val_i8 := GetProcAddress(aDLLHandle, 'gguf_get_val_i8');
  gguf_get_val_str := GetProcAddress(aDLLHandle, 'gguf_get_val_str');
  gguf_get_val_u16 := GetProcAddress(aDLLHandle, 'gguf_get_val_u16');
  gguf_get_val_u32 := GetProcAddress(aDLLHandle, 'gguf_get_val_u32');
  gguf_get_val_u64 := GetProcAddress(aDLLHandle, 'gguf_get_val_u64');
  gguf_get_val_u8 := GetProcAddress(aDLLHandle, 'gguf_get_val_u8');
  gguf_get_version := GetProcAddress(aDLLHandle, 'gguf_get_version');
  gguf_init_empty := GetProcAddress(aDLLHandle, 'gguf_init_empty');
  gguf_init_from_file := GetProcAddress(aDLLHandle, 'gguf_init_from_file');
  gguf_remove_key := GetProcAddress(aDLLHandle, 'gguf_remove_key');
  gguf_set_arr_data := GetProcAddress(aDLLHandle, 'gguf_set_arr_data');
  gguf_set_arr_str := GetProcAddress(aDLLHandle, 'gguf_set_arr_str');
  gguf_set_kv := GetProcAddress(aDLLHandle, 'gguf_set_kv');
  gguf_set_tensor_data := GetProcAddress(aDLLHandle, 'gguf_set_tensor_data');
  gguf_set_tensor_type := GetProcAddress(aDLLHandle, 'gguf_set_tensor_type');
  gguf_set_val_bool := GetProcAddress(aDLLHandle, 'gguf_set_val_bool');
  gguf_set_val_f32 := GetProcAddress(aDLLHandle, 'gguf_set_val_f32');
  gguf_set_val_f64 := GetProcAddress(aDLLHandle, 'gguf_set_val_f64');
  gguf_set_val_i16 := GetProcAddress(aDLLHandle, 'gguf_set_val_i16');
  gguf_set_val_i32 := GetProcAddress(aDLLHandle, 'gguf_set_val_i32');
  gguf_set_val_i64 := GetProcAddress(aDLLHandle, 'gguf_set_val_i64');
  gguf_set_val_i8 := GetProcAddress(aDLLHandle, 'gguf_set_val_i8');
  gguf_set_val_str := GetProcAddress(aDLLHandle, 'gguf_set_val_str');
  gguf_set_val_u16 := GetProcAddress(aDLLHandle, 'gguf_set_val_u16');
  gguf_set_val_u32 := GetProcAddress(aDLLHandle, 'gguf_set_val_u32');
  gguf_set_val_u64 := GetProcAddress(aDLLHandle, 'gguf_set_val_u64');
  gguf_set_val_u8 := GetProcAddress(aDLLHandle, 'gguf_set_val_u8');
  gguf_type_name := GetProcAddress(aDLLHandle, 'gguf_type_name');
  gguf_write_to_file := GetProcAddress(aDLLHandle, 'gguf_write_to_file');
  llama_add_bos_token := GetProcAddress(aDLLHandle, 'llama_add_bos_token');
  llama_add_eos_token := GetProcAddress(aDLLHandle, 'llama_add_eos_token');
  llama_attach_threadpool := GetProcAddress(aDLLHandle, 'llama_attach_threadpool');
  llama_backend_free := GetProcAddress(aDLLHandle, 'llama_backend_free');
  llama_backend_init := GetProcAddress(aDLLHandle, 'llama_backend_init');
  llama_batch_free := GetProcAddress(aDLLHandle, 'llama_batch_free');
  llama_batch_get_one := GetProcAddress(aDLLHandle, 'llama_batch_get_one');
  llama_batch_init := GetProcAddress(aDLLHandle, 'llama_batch_init');
  llama_chat_apply_template := GetProcAddress(aDLLHandle, 'llama_chat_apply_template');
  llama_chat_builtin_templates := GetProcAddress(aDLLHandle, 'llama_chat_builtin_templates');
  llama_context_default_params := GetProcAddress(aDLLHandle, 'llama_context_default_params');
  llama_control_vector_apply := GetProcAddress(aDLLHandle, 'llama_control_vector_apply');
  llama_copy_state_data := GetProcAddress(aDLLHandle, 'llama_copy_state_data');
  llama_decode := GetProcAddress(aDLLHandle, 'llama_decode');
  llama_detach_threadpool := GetProcAddress(aDLLHandle, 'llama_detach_threadpool');
  llama_detokenize := GetProcAddress(aDLLHandle, 'llama_detokenize');
  llama_encode := GetProcAddress(aDLLHandle, 'llama_encode');
  llama_free := GetProcAddress(aDLLHandle, 'llama_free');
  llama_free_model := GetProcAddress(aDLLHandle, 'llama_free_model');
  llama_get_embeddings := GetProcAddress(aDLLHandle, 'llama_get_embeddings');
  llama_get_embeddings_ith := GetProcAddress(aDLLHandle, 'llama_get_embeddings_ith');
  llama_get_embeddings_seq := GetProcAddress(aDLLHandle, 'llama_get_embeddings_seq');
  llama_get_kv_cache_token_count := GetProcAddress(aDLLHandle, 'llama_get_kv_cache_token_count');
  llama_get_kv_cache_used_cells := GetProcAddress(aDLLHandle, 'llama_get_kv_cache_used_cells');
  llama_get_logits := GetProcAddress(aDLLHandle, 'llama_get_logits');
  llama_get_logits_ith := GetProcAddress(aDLLHandle, 'llama_get_logits_ith');
  llama_get_model := GetProcAddress(aDLLHandle, 'llama_get_model');
  llama_get_state_size := GetProcAddress(aDLLHandle, 'llama_get_state_size');
  llama_kv_cache_can_shift := GetProcAddress(aDLLHandle, 'llama_kv_cache_can_shift');
  llama_kv_cache_clear := GetProcAddress(aDLLHandle, 'llama_kv_cache_clear');
  llama_kv_cache_defrag := GetProcAddress(aDLLHandle, 'llama_kv_cache_defrag');
  llama_kv_cache_seq_add := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_add');
  llama_kv_cache_seq_cp := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_cp');
  llama_kv_cache_seq_div := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_div');
  llama_kv_cache_seq_keep := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_keep');
  llama_kv_cache_seq_pos_max := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_pos_max');
  llama_kv_cache_seq_rm := GetProcAddress(aDLLHandle, 'llama_kv_cache_seq_rm');
  llama_kv_cache_update := GetProcAddress(aDLLHandle, 'llama_kv_cache_update');
  llama_kv_cache_view_free := GetProcAddress(aDLLHandle, 'llama_kv_cache_view_free');
  llama_kv_cache_view_init := GetProcAddress(aDLLHandle, 'llama_kv_cache_view_init');
  llama_kv_cache_view_update := GetProcAddress(aDLLHandle, 'llama_kv_cache_view_update');
  llama_load_model_from_file := GetProcAddress(aDLLHandle, 'llama_load_model_from_file');
  llama_load_session_file := GetProcAddress(aDLLHandle, 'llama_load_session_file');
  llama_log_set := GetProcAddress(aDLLHandle, 'llama_log_set');
  llama_lora_adapter_clear := GetProcAddress(aDLLHandle, 'llama_lora_adapter_clear');
  llama_lora_adapter_free := GetProcAddress(aDLLHandle, 'llama_lora_adapter_free');
  llama_lora_adapter_init := GetProcAddress(aDLLHandle, 'llama_lora_adapter_init');
  llama_lora_adapter_remove := GetProcAddress(aDLLHandle, 'llama_lora_adapter_remove');
  llama_lora_adapter_set := GetProcAddress(aDLLHandle, 'llama_lora_adapter_set');
  llama_max_devices := GetProcAddress(aDLLHandle, 'llama_max_devices');
  llama_model_decoder_start_token := GetProcAddress(aDLLHandle, 'llama_model_decoder_start_token');
  llama_model_default_params := GetProcAddress(aDLLHandle, 'llama_model_default_params');
  llama_model_desc := GetProcAddress(aDLLHandle, 'llama_model_desc');
  llama_model_has_decoder := GetProcAddress(aDLLHandle, 'llama_model_has_decoder');
  llama_model_has_encoder := GetProcAddress(aDLLHandle, 'llama_model_has_encoder');
  llama_model_is_recurrent := GetProcAddress(aDLLHandle, 'llama_model_is_recurrent');
  llama_model_meta_count := GetProcAddress(aDLLHandle, 'llama_model_meta_count');
  llama_model_meta_key_by_index := GetProcAddress(aDLLHandle, 'llama_model_meta_key_by_index');
  llama_model_meta_val_str := GetProcAddress(aDLLHandle, 'llama_model_meta_val_str');
  llama_model_meta_val_str_by_index := GetProcAddress(aDLLHandle, 'llama_model_meta_val_str_by_index');
  llama_model_n_params := GetProcAddress(aDLLHandle, 'llama_model_n_params');
  llama_model_quantize := GetProcAddress(aDLLHandle, 'llama_model_quantize');
  llama_model_quantize_default_params := GetProcAddress(aDLLHandle, 'llama_model_quantize_default_params');
  llama_model_size := GetProcAddress(aDLLHandle, 'llama_model_size');
  llama_n_batch := GetProcAddress(aDLLHandle, 'llama_n_batch');
  llama_n_ctx := GetProcAddress(aDLLHandle, 'llama_n_ctx');
  llama_n_ctx_train := GetProcAddress(aDLLHandle, 'llama_n_ctx_train');
  llama_n_embd := GetProcAddress(aDLLHandle, 'llama_n_embd');
  llama_n_head := GetProcAddress(aDLLHandle, 'llama_n_head');
  llama_n_layer := GetProcAddress(aDLLHandle, 'llama_n_layer');
  llama_n_seq_max := GetProcAddress(aDLLHandle, 'llama_n_seq_max');
  llama_n_threads := GetProcAddress(aDLLHandle, 'llama_n_threads');
  llama_n_threads_batch := GetProcAddress(aDLLHandle, 'llama_n_threads_batch');
  llama_n_ubatch := GetProcAddress(aDLLHandle, 'llama_n_ubatch');
  llama_n_vocab := GetProcAddress(aDLLHandle, 'llama_n_vocab');
  llama_new_context_with_model := GetProcAddress(aDLLHandle, 'llama_new_context_with_model');
  llama_numa_init := GetProcAddress(aDLLHandle, 'llama_numa_init');
  llama_perf_context := GetProcAddress(aDLLHandle, 'llama_perf_context');
  llama_perf_context_print := GetProcAddress(aDLLHandle, 'llama_perf_context_print');
  llama_perf_context_reset := GetProcAddress(aDLLHandle, 'llama_perf_context_reset');
  llama_perf_sampler := GetProcAddress(aDLLHandle, 'llama_perf_sampler');
  llama_perf_sampler_print := GetProcAddress(aDLLHandle, 'llama_perf_sampler_print');
  llama_perf_sampler_reset := GetProcAddress(aDLLHandle, 'llama_perf_sampler_reset');
  llama_pooling_type_rtn := GetProcAddress(aDLLHandle, 'llama_pooling_type');
  llama_print_system_info := GetProcAddress(aDLLHandle, 'llama_print_system_info');
  llama_rope_freq_scale_train := GetProcAddress(aDLLHandle, 'llama_rope_freq_scale_train');
  llama_rope_type_rtn := GetProcAddress(aDLLHandle, 'llama_rope_type');
  llama_sampler_accept := GetProcAddress(aDLLHandle, 'llama_sampler_accept');
  llama_sampler_apply := GetProcAddress(aDLLHandle, 'llama_sampler_apply');
  llama_sampler_chain_add := GetProcAddress(aDLLHandle, 'llama_sampler_chain_add');
  llama_sampler_chain_default_params := GetProcAddress(aDLLHandle, 'llama_sampler_chain_default_params');
  llama_sampler_chain_get := GetProcAddress(aDLLHandle, 'llama_sampler_chain_get');
  llama_sampler_chain_init := GetProcAddress(aDLLHandle, 'llama_sampler_chain_init');
  llama_sampler_chain_n := GetProcAddress(aDLLHandle, 'llama_sampler_chain_n');
  llama_sampler_chain_remove := GetProcAddress(aDLLHandle, 'llama_sampler_chain_remove');
  llama_sampler_clone := GetProcAddress(aDLLHandle, 'llama_sampler_clone');
  llama_sampler_free := GetProcAddress(aDLLHandle, 'llama_sampler_free');
  llama_sampler_get_seed := GetProcAddress(aDLLHandle, 'llama_sampler_get_seed');
  llama_sampler_init_dist := GetProcAddress(aDLLHandle, 'llama_sampler_init_dist');
  llama_sampler_init_dry := GetProcAddress(aDLLHandle, 'llama_sampler_init_dry');
  llama_sampler_init_grammar := GetProcAddress(aDLLHandle, 'llama_sampler_init_grammar');
  llama_sampler_init_greedy := GetProcAddress(aDLLHandle, 'llama_sampler_init_greedy');
  llama_sampler_init_infill := GetProcAddress(aDLLHandle, 'llama_sampler_init_infill');
  llama_sampler_init_logit_bias := GetProcAddress(aDLLHandle, 'llama_sampler_init_logit_bias');
  llama_sampler_init_min_p := GetProcAddress(aDLLHandle, 'llama_sampler_init_min_p');
  llama_sampler_init_mirostat := GetProcAddress(aDLLHandle, 'llama_sampler_init_mirostat');
  llama_sampler_init_mirostat_v2 := GetProcAddress(aDLLHandle, 'llama_sampler_init_mirostat_v2');
  llama_sampler_init_penalties := GetProcAddress(aDLLHandle, 'llama_sampler_init_penalties');
  llama_sampler_init_softmax := GetProcAddress(aDLLHandle, 'llama_sampler_init_softmax');
  llama_sampler_init_temp := GetProcAddress(aDLLHandle, 'llama_sampler_init_temp');
  llama_sampler_init_temp_ext := GetProcAddress(aDLLHandle, 'llama_sampler_init_temp_ext');
  llama_sampler_init_top_k := GetProcAddress(aDLLHandle, 'llama_sampler_init_top_k');
  llama_sampler_init_top_p := GetProcAddress(aDLLHandle, 'llama_sampler_init_top_p');
  llama_sampler_init_typical := GetProcAddress(aDLLHandle, 'llama_sampler_init_typical');
  llama_sampler_init_xtc := GetProcAddress(aDLLHandle, 'llama_sampler_init_xtc');
  llama_sampler_name := GetProcAddress(aDLLHandle, 'llama_sampler_name');
  llama_sampler_reset := GetProcAddress(aDLLHandle, 'llama_sampler_reset');
  llama_sampler_sample := GetProcAddress(aDLLHandle, 'llama_sampler_sample');
  llama_save_session_file := GetProcAddress(aDLLHandle, 'llama_save_session_file');
  llama_set_abort_callback := GetProcAddress(aDLLHandle, 'llama_set_abort_callback');
  llama_set_causal_attn := GetProcAddress(aDLLHandle, 'llama_set_causal_attn');
  llama_set_embeddings := GetProcAddress(aDLLHandle, 'llama_set_embeddings');
  llama_set_n_threads := GetProcAddress(aDLLHandle, 'llama_set_n_threads');
  llama_set_state_data := GetProcAddress(aDLLHandle, 'llama_set_state_data');
  llama_split_path := GetProcAddress(aDLLHandle, 'llama_split_path');
  llama_split_prefix := GetProcAddress(aDLLHandle, 'llama_split_prefix');
  llama_state_get_data := GetProcAddress(aDLLHandle, 'llama_state_get_data');
  llama_state_get_size := GetProcAddress(aDLLHandle, 'llama_state_get_size');
  llama_state_load_file := GetProcAddress(aDLLHandle, 'llama_state_load_file');
  llama_state_save_file := GetProcAddress(aDLLHandle, 'llama_state_save_file');
  llama_state_seq_get_data := GetProcAddress(aDLLHandle, 'llama_state_seq_get_data');
  llama_state_seq_get_size := GetProcAddress(aDLLHandle, 'llama_state_seq_get_size');
  llama_state_seq_load_file := GetProcAddress(aDLLHandle, 'llama_state_seq_load_file');
  llama_state_seq_save_file := GetProcAddress(aDLLHandle, 'llama_state_seq_save_file');
  llama_state_seq_set_data := GetProcAddress(aDLLHandle, 'llama_state_seq_set_data');
  llama_state_set_data := GetProcAddress(aDLLHandle, 'llama_state_set_data');
  llama_supports_gpu_offload := GetProcAddress(aDLLHandle, 'llama_supports_gpu_offload');
  llama_supports_mlock := GetProcAddress(aDLLHandle, 'llama_supports_mlock');
  llama_supports_mmap := GetProcAddress(aDLLHandle, 'llama_supports_mmap');
  llama_supports_rpc := GetProcAddress(aDLLHandle, 'llama_supports_rpc');
  llama_synchronize := GetProcAddress(aDLLHandle, 'llama_synchronize');
  llama_time_us := GetProcAddress(aDLLHandle, 'llama_time_us');
  llama_token_bos := GetProcAddress(aDLLHandle, 'llama_token_bos');
  llama_token_cls := GetProcAddress(aDLLHandle, 'llama_token_cls');
  llama_token_eos := GetProcAddress(aDLLHandle, 'llama_token_eos');
  llama_token_eot := GetProcAddress(aDLLHandle, 'llama_token_eot');
  llama_token_fim_mid := GetProcAddress(aDLLHandle, 'llama_token_fim_mid');
  llama_token_fim_pad := GetProcAddress(aDLLHandle, 'llama_token_fim_pad');
  llama_token_fim_pre := GetProcAddress(aDLLHandle, 'llama_token_fim_pre');
  llama_token_fim_rep := GetProcAddress(aDLLHandle, 'llama_token_fim_rep');
  llama_token_fim_sep := GetProcAddress(aDLLHandle, 'llama_token_fim_sep');
  llama_token_fim_suf := GetProcAddress(aDLLHandle, 'llama_token_fim_suf');
  llama_token_get_attr := GetProcAddress(aDLLHandle, 'llama_token_get_attr');
  llama_token_get_score := GetProcAddress(aDLLHandle, 'llama_token_get_score');
  llama_token_get_text := GetProcAddress(aDLLHandle, 'llama_token_get_text');
  llama_token_is_control := GetProcAddress(aDLLHandle, 'llama_token_is_control');
  llama_token_is_eog := GetProcAddress(aDLLHandle, 'llama_token_is_eog');
  llama_token_middle := GetProcAddress(aDLLHandle, 'llama_token_middle');
  llama_token_nl := GetProcAddress(aDLLHandle, 'llama_token_nl');
  llama_token_pad := GetProcAddress(aDLLHandle, 'llama_token_pad');
  llama_token_prefix := GetProcAddress(aDLLHandle, 'llama_token_prefix');
  llama_token_sep := GetProcAddress(aDLLHandle, 'llama_token_sep');
  llama_token_suffix := GetProcAddress(aDLLHandle, 'llama_token_suffix');
  llama_token_to_piece := GetProcAddress(aDLLHandle, 'llama_token_to_piece');
  llama_tokenize := GetProcAddress(aDLLHandle, 'llama_tokenize');
  llama_vocab_type_rtn := GetProcAddress(aDLLHandle, 'llama_vocab_type');
  redirect_cerr_to_callback := GetProcAddress(aDLLHandle, 'redirect_cerr_to_callback');
  restore_cerr := GetProcAddress(aDLLHandle, 'restore_cerr');
end;

{$ENDREGION}

{$REGION ' Lumina.Common '}
var
  Marshaller: TMarshaller;

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

function AsUTF8(const AText: string): Pointer;
begin
  Result := Marshaller.AsUtf8(AText).ToPointer;
end;

function EnableVirtualTerminalProcessing(): DWORD;
var
  HOut: THandle;
  LMode: DWORD;
begin
  HOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if HOut = INVALID_HANDLE_VALUE then
  begin
    Result := GetLastError;
    Exit;
  end;

  if not GetConsoleMode(HOut, LMode) then
  begin
    Result := GetLastError;
    Exit;
  end;

  LMode := LMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  if not SetConsoleMode(HOut, LMode) then
  begin
    Result := GetLastError;
    Exit;
  end;

  Result := 0;  // Success
end;

function ResourceExists(aInstance: THandle; const aResName: string): Boolean;
begin
  Result := Boolean((FindResource(aInstance, PChar(aResName), RT_RCDATA) <> 0));
end;

function HasConsoleOutput: Boolean;
var
  Stdout: THandle;
begin
  Stdout := GetStdHandle(Std_Output_Handle);
  Win32Check(Stdout <> Invalid_Handle_Value);
  Result := Stdout <> 0;
end;

function GetPhysicalProcessorCount(): DWORD;
var
  BufferSize: DWORD;
  Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION;
  ProcessorInfo: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION;
  Offset: DWORD;
begin
  Result := 0;
  BufferSize := 0;

  // Call GetLogicalProcessorInformation with buffer size set to 0 to get required buffer size
  if not GetLogicalProcessorInformation(nil, BufferSize) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
  begin
    // Allocate buffer
    GetMem(Buffer, BufferSize);
    try
      // Call GetLogicalProcessorInformation again with allocated buffer
      if GetLogicalProcessorInformation(Buffer, BufferSize) then
      begin
        ProcessorInfo := Buffer;
        Offset := 0;

        // Loop through processor information to count physical processors
        while Offset + SizeOf(SYSTEM_LOGICAL_PROCESSOR_INFORMATION) <= BufferSize do
        begin
          if ProcessorInfo.Relationship = RelationProcessorCore then
            Inc(Result);

          Inc(ProcessorInfo);
          Inc(Offset, SizeOf(SYSTEM_LOGICAL_PROCESSOR_INFORMATION));
        end;
      end;
    finally
      FreeMem(Buffer);
    end;
  end;
end;

procedure  GetConsoleSize(AWidth: PInteger; AHeight: PInteger);
var
  LConsoleInfo: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), LConsoleInfo);
  if Assigned(AWidth) then
    AWidth^ := LConsoleInfo.dwSize.X;

  if Assigned(AHeight) then
  AHeight^ := LConsoleInfo.dwSize.Y;
end;

function HasEnoughDiskSpace(const APath: string; ARequiredSpace: Int64): Boolean;
var
  LFreeAvailable: Int64;
  LTotalSpace: Int64;
  LTotalFree: Int64;
begin
  Result := GetDiskFreeSpaceEx(PChar(APath), LFreeAvailable, LTotalSpace, @LTotalFree) and
            (LFreeAvailable >= ARequiredSpace);
end;

{ TBaseObject }
constructor TBaseObject.Create();
begin
  inherited;
end;

destructor TBaseObject.Destroy();
begin
  inherited;
end;

{ TTokenResponse }
class operator TTokenResponse.Initialize (out ADest: TTokenResponse);
var
  LSize: Integer;
begin
  // Defaults
  ADest.FRaw := '';
  SetLength(ADest.FTokens, 0);
  SetLength(ADest.FWordBreaks, 0);
  SetLength(ADest.FLineBreaks, 0);
  SetLength(ADest.FWords, 0);
  ADest.FWord := '';
  ADest.FLine := '';
  ADest.FFinalized := False;
  ADest.FRightMargin := 10;

  // If stream output is sent to a destination without wordwrap,
  // the TTokenResponse will find wordbreaks and split into lines by full words

  // Stream is tabulated into full words based on these break characters
  // !Syntax requires at least one!
  SetLength(ADest.FWordBreaks, 4);
  ADest.FWordBreaks[0] := ' ';
  ADest.FWordBreaks[1] := '-';
  ADest.FWordBreaks[2] := ',';
  ADest.FWordBreaks[3] := '.';

  // Stream may contain forced line breaks
  // !Syntax requires at least one!
  SetLength(ADest.FLineBreaks, 2);
  ADest.FLineBreaks[0] := #13;
  ADest.FLineBreaks[1] := #10;


  ADest.SetRightMargin(10);

  GetConsoleSize(@LSize, nil);
  ADest.SetMaxLineLength(LSize);
end;

function TTokenResponse.AddToken(const aToken: string): TTokenPrintAction;
var
  LPrefix, LSuffix: string;
begin
  // Keep full original response
  FRaw := FRaw + aToken;                    // As continuous string
  Setlength(FTokens, Length(FTokens)+1);    // Make space
  FTokens[Length(FTokens)-1] := aToken;     // As an array

  // Accumulate "word"
  FWord := FWord + aToken;

  // If stream contains linebreaks, print token out without added linebreaks
  if HandleLineBreaks(aToken) then
    exit(TTokenPrintAction.tpaAppend)

  // Check if a natural break exists, also split if word is longer than the allowed space
  // and print out token with or without linechange as needed
  else if SplitWord(FWord, LPrefix, LSuffix) or FFinalized then
    begin
      // On last call when Finalized we want access to the line change logic only
      // Bad design (fix on top of a fix) Would be better to separate word slipt and line logic from eachother
      if not FFinalized then
        begin
          Setlength(FWords, Length(FWords)+1);        // Make space
          FWords[Length(FWords)-1] := LPrefix;        // Add new word to array
          FWord := LSuffix;                         // Keep the remainder of the split
        end;

      // Word was split, so there is something that can be printed

      // Need for a new line?
      if Length(FLine) + Length(LastWord) > GetLineLengthMax() then
        begin
          Result  := TTokenPrintAction.tpaNewline;
          FLine   := LastWord;                  // Reset Line (will be new line and then the word)
        end
      else
        begin
          Result  := TTokenPrintAction.tpaAppend;
          FLine   := FLine + LastWord;          // Append to the line
        end;
    end
  else
    begin
      Result := TTokenPrintAction.tpaWait;
    end;
end;

function TTokenResponse.HandleLineBreaks(const AToken: string): Boolean;
var
  LLetter, LLineBreak: Integer;
begin
  Result := false;

  for LLetter := Length(AToken) downto 1 do                   // We are interested in the last possible linebreak
  begin
    for LLineBReak := 0 to Length(Self.FLineBreaks)-1 do       // Iterate linebreaks
    begin
      if AToken[LLetter] = FLineBreaks[LLineBreak] then        // If linebreak was found
      begin
        // Split into a word by last found linechange (do note the stored word may have more linebreak)
        Setlength(FWords, Length(FWords)+1);                          // Make space
        FWords[Length(FWords)-1] := FWord + LeftStr(AToken, Length(AToken)-LLetter); // Add new word to array

        // In case aToken did not end after last LF
        // Word and new line will have whatever was after the last linebreak
        FWord := RightStr(AToken, Length(AToken)-LLetter);
        FLine := FWord;

        // No need to go further
        exit(true);
      end;
    end;
  end;
end;

function TTokenResponse.Finalize: Boolean;
begin
  // Buffer may contain something, if so make it into a word
  if FWord <> ''  then
    begin
      Setlength(FWords, Length(FWords)+1);      // Make space
      FWords[Length(FWords)-1] := FWord;        // Add new word to array
      Self.FFinalized := True;                // Remember Finalize was done (affects how last AddToken-call behaves)
      exit(true);
    end
  else
    Result := false;
end;

function TTokenResponse.LastWord(const ATrimLeft: Boolean): string;
begin
  Result := FWords[Length(FWords)-1];
  if ATrimLeft then
    Result := Result.TrimLeft;
end;

function TTokenResponse.SplitWord(const AWord: string; var APrefix, ASuffix: string): Boolean;
var
  LLetter, LSeparator: Integer;
begin
  Result := false;

  for LLetter := 1 to Length(AWord) do               // Iterate whole word
  begin
    for LSeparator := 0 to Length(FWordBreaks)-1 do   // Iterate all separating characters
    begin
      if AWord[LLetter] = FWordBreaks[LSeparator] then // check for natural break
      begin
        // Let the world know there's stuff that can be a reason for a line change
        Result := True;

        APrefix := LeftStr(AWord, LLetter);
        ASuffix := RightStr(AWord, Length(AWord)-LLetter);
      end;
    end;
  end;

  // Maybe the word is too long but there was no natural break, then cut it to LineLengthMax
  if Length(AWord) > GetLineLengthMax() then
  begin
    Result := True;
    APrefix := LeftStr(AWord, GetLineLengthMax());
    ASuffix := RightStr(AWord, Length(AWord)-GetLineLengthMax());
  end;
end;

(*

function TTokenResponse.GetLineLengthMax(): Integer;
begin
  GetConsoleSize(@Result, nil);
  Result := Result - FRightMargin;
end;

procedure TTokenResponse.SetRightMargin(const AMargin: Integer);
var
  LWidth: Integer;
begin
  GetConsoleSize(@LWidth, nil);
  FRightMargin := EnsureRange(AMargin, 1, LWidth);
end;
*)

function TTokenResponse.GetLineLengthMax(): Integer;
begin
  Result := FMaxLineLength - FRightMargin;
end;

procedure TTokenResponse.SetRightMargin(const AMargin: Integer);
begin
  FRightMargin := AMargin;
end;

procedure TTokenResponse.SetMaxLineLength(const ALength: Integer);
begin
  FMaxLineLength := ALength;
end;

{$ENDREGION}

{$REGION ' Lumina '}
{ TLumina }
function TLumina.TokenToPiece(const AContext: Pllama_context; const AToken: llama_token; const ASpecial: Boolean): string;
var
  LTokens: Int32;
  LCheck: Int32;
  LBuffer: TArray<UTF8Char>;
begin
  try
    SetLength(LBuffer, 9);
    LTokens := llama_token_to_piece(llama_get_model(AContext), AToken, @LBuffer[0], 8, 0, ASpecial);
    if LTokens < 0 then
      begin
        SetLength(LBuffer, (-LTokens)+1);
        LCheck := llama_token_to_piece(llama_get_model(AContext), AToken, @LBuffer[0], -LTokens, 0, ASpecial);
        Assert(LCheck = -LTokens);
        LBuffer[-LTokens] := #0;
      end
    else
      begin
        LBuffer[LTokens] := #0;
      end;
    Result := UTF8ToString(@LBuffer[0]);
  except
    on E: Exception do
    begin
      SetError(E.Message, []);
      Exit;
    end;
  end;
end;

function TLumina.CalcPerformance(const AContext: Pllama_context): PerformanceResult;
var
  LTotalTimeSec: Double;
  APerfData: llama_perf_context_data;
begin
  APerfData := llama_perf_context(AContext);

  // Convert milliseconds to seconds
  LTotalTimeSec := APerfData.t_eval_ms / 1000;

  // Total input tokens (n_p_eval assumed to be input tokens)
  Result.TotalInputTokens := APerfData.n_p_eval;

  // Total output tokens (n_eval assumed to be output tokens)
  Result.TotalOutputTokens := APerfData.n_eval;

  // Calculate tokens per second (total tokens / time in seconds)
  if LTotalTimeSec > 0 then
    Result.TokensPerSecond := (Result.TotalInputTokens + Result.TotalOutputTokens) / LTotalTimeSec
  else
    Result.TokensPerSecond := 0;
end;

procedure TLumina.Print(const AText: string; const AArgs: array of const);
begin
  if not HasConsoleOutput() then Exit;
  Write(Format(AText, AArgs));
end;

procedure TLumina.PrintLn(const AText: string; const AArgs: array of const);
begin
  if not HasConsoleOutput() then Exit;
  WriteLn(Format(AText, AArgs));
end;

procedure TLumina.SetError(const AText: string; const AArgs: array of const);
begin
  FError := Format(AText, AArgs);
end;

function TLumina.OnCancel(): Boolean;
begin
  if Assigned(FCancelCallback.Handler) then
    Result := FCancelCallback.Handler(FCancelCallback.UserData)
  else
    // check for ESC press by default
    Result := Boolean(GetAsyncKeyState(VK_ESCAPE) <> 0);
end;

procedure TLumina.OnNextToken(const AToken: string);
begin
  if Assigned(FNextTokenCallback.Handler) then
    FNextTokenCallback.Handler(AToken, FNextTokenCallback.UserData)
  else
    Print(AToken, []);
end;

procedure TLumina.OnProgress(const AProgress: Single);
begin
  FModelProgress := AProgress * 100.0;

  if Assigned(FProgressCallback.Handler) then
  begin
    FProgressCallback.Handler(FModelFilename, FModelProgress, FProgressCallback.UserData);
    Exit;
  end;

  Print(#13+'Loading %s(%3.2f%%)...', [FModelFilename, FModelProgress]);
  if FModelProgress >= 100  then
  begin
    // clear line
    Print(#13 + #27 + '[K', []);
  end;
end;

procedure TLumina.OnInfo(const AText: string);
begin
  if Assigned(FInfoCallback.Handler) then
    FInfoCallback.Handler(AText, FInfoCallback.UserData)
  else
    Print(AText, []);
end;

procedure TLumina_LogCallback(ALevel: ggml_log_level; const AText: PUTF8Char; AUserData: Pointer); cdecl;
var
  LLumina: TLumina;
begin
  if not Assigned(AUserData) then Exit;

  LLumina := TLumina(AUserData);
  LLumina.OnInfo(string(AText));
end;

procedure TLumina_CerrCallback(const AText: PUTF8Char; AUserData: Pointer); cdecl;
var
  LLumina: TLumina;
begin
  if not Assigned(AUserData) then Exit;

  LLumina := TLumina(AUserData);
  LLumina.OnInfo(string(AText));
end;

function TLumina_ProgressCallback(AProgress: Single; AUserData: Pointer): Boolean; cdecl;
var
  LLumina: TLumina;
begin
  Result := True;
  if not Assigned(AUserData) then Exit;

  LLumina := TLumina(AUserData);
  LLumina.OnProgress(AProgress);
end;

constructor TLumina.Create();
begin
  inherited;
end;

destructor TLumina.Destroy();
begin
  UnloadModel();
  inherited;
end;

function  TLumina.GetError(): string;
begin
  Result := FError;
end;

procedure TLumina.SetLineOutputInfo(const ARightMargin: Int32; const AMaxLineLength: Int32);
begin
  if ARightMargin > -1 then
  begin
    FLineOutputRightMargin := ARightMargin;
    FTokenResponse.SetRightMargin(FLineOutputRightMargin);
  end;

  if AMaxLineLength > -1 then
  begin
    FLineOutputMaxLineLength := AMaxLineLength;
    FTokenResponse.SetMaxLineLength(AMaxLineLength)
  end;
end;

procedure TLumina.GetLineOutputInfo(const ARightMargin: PInt32; const AMaxLineLength: PInt32);
begin
  if Assigned(ARightMargin) then
    ARightMargin^ := FLineOutputRightMargin;

  if Assigned(AMaxLineLength) then
    AMaxLineLength^ := FLineOutputMaxLineLength;
end;

function  TLumina.GetNextTokenCallback(): NextTokenCallback;
begin
  Result := FNextTokenCallback.Handler;
end;

procedure TLumina.SetNextTokenCallback(const AHandler: NextTokenCallback; const AUserData: Pointer);
begin
  FNextTokenCallback.Handler := AHandler;
  FNextTokenCallback.UserData := AUserData;
end;

function  TLumina.GetCancelCallback(): TLumina.CancelCallback;
begin
  Result := FCancelCallback.Handler;
end;

procedure TLumina.SetCancelCallback(const AHandler: CancelCallback; const AUserData: Pointer);
begin
  FCancelCallback.Handler := AHandler;
  FCancelCallback.UserData := AUserData;
end;

function  TLumina.GetProgressCallback(): TLumina.ProgressCallback;
begin
  Result := FProgressCallback.Handler;
end;

procedure TLumina.SetProgressCallback(const AHandler: TLumina.ProgressCallback; const AUserData: Pointer);
begin
  FProgressCallback.Handler := AHandler;
  FProgressCallback.UserData := AUserData;
end;

function  TLumina.GetInfoCallback(): TLumina.InfoCallback;
begin
  Result := FInfoCallback.Handler;
end;

procedure TLumina.SetInfoCallback(const AHandler: TLumina.InfoCallback; const AUserData: Pointer);
begin
  FInfoCallback.Handler := AHandler;
  FInfoCallback.UserData := AUserData;
end;

function  TLumina.LoadModel(const AModelFilename: string; const ATempate: string=''; const AMaxContext: UInt32=512; const AGPULayers: Int32=-1; const AMaxThreads: Int32=4): Boolean;
begin
  Result := False;

  if Assigned(FModel) then
  begin
    SetError('Model already loaded', []);
    Exit;
  end;

  FModelFilename  := AModelFilename;
  FModelProgress  := 0;
  FModelTemplate  := ATempate;
  FModelMaxContex := AMaxContext;
  FGPULayers  := AGPULayers;
  FMaxThreads := AMaxThreads;

  redirect_cerr_to_callback(TLumina_CerrCallback, nil);

  llama_log_set(TLumina_LogCallback, Self);

  FModelParams := llama_model_default_params();

  FModelParams.progress_callback := TLumina_ProgressCallback;
  FModelParams.progress_callback_user_data := Self;

  if FGPULayers < 0 then
    FModelParams.n_gpu_layers := MaxInt
  else
    FModelParams.n_gpu_layers := FGPULayers;

  FModel :=  llama_load_model_from_file( AsUtf8(FModelFilename), FModelParams);
  if not Assigned(FModel) then
  begin
    SetError('Failed to load model: "%s"', [FModelFilename]);
    Exit;
  end;

  Result := True;
end;

procedure TLumina.UnloadModel();
begin
  if Assigned(FModel) then
  begin
    llama_free_model(FModel);
    FModel := nil;
    restore_cerr();
  end;
end;

function TLumina.SimpleInference(const AQuestion: string): Boolean;
var
  LNumPrompt: Integer;
  LPromptTokens: TArray<llama_token>;
  LCtxParams: llama_context_params;
  LNumPredict: integer;
  LCtx: Pllama_context;
  LSmplrParams: llama_sampler_chain_params;
  LSmplr: Pllama_sampler;
  N: Integer;
  LTokenStr: string;
  LBatch: llama_batch;
  LNewTokenId: llama_token;
  LNumPos: Integer;
  LPrompt: UTF8String;
  LText: string;
  LFirstToken: Boolean;
  LBuffer: array of UTF8Char;
  V: Int32;
  LBuf: array[0..255] of UTF8Char;
  LKey: string;
  LMaxContext: integer;

  function BuildPrompt(const AModel: Pllama_model; const AText: string): PUTF8Char;
  var
    LChatMsgs: llama_chat_message;
    LSize, LTmplSize: integer;
  begin
    LChatMsgs.role := 'user';
    LChatMsgs.content := AsUTF8(AText);
    LSize := StrLen(LChatMsgs.content);
    LSize := (LSize * 2) + 512;
    SetLength(LBuffer, LSize);
    FillChar(LBuffer[0], LSize, 0);

    LTmplSize := llama_chat_apply_template(AModel, nil, @LChatMsgs, 1, True, @LBuffer[0], LSize);
    if LTmplSize > LSize then
    begin
      LBuffer := nil;
      SetLength(LBuffer, LTmplSize);
      llama_chat_apply_template(AModel, nil, @LChatMsgs, 1, True, @LBuffer[0], LTmplSize);
    end;
    Result := @LBuffer[0];
  end;

begin
  Result := False;

  if not Assigned(FModel) then
  begin
    SetError('No model loaded', []);
    Exit;
  end;

  FError := '';
  LFirstToken := True;
  LMaxContext := 0;

  for V := 0 to llama_model_meta_count(FModel)-1 do
  begin
    llama_model_meta_key_by_index(FModel, V, @LBuf[0], length(LBuf));
    LKey := string(LBuf);
    if LKey.Contains('context_length') then
    begin
      llama_model_meta_val_str_by_index(FModel, V, @LBuf[0], length(LBuf));
      LKey := string(LBuf);
      LMaxContext :=  LKey.ToInteger;
      break;
    end;
  end;

  if LMaxContext > 0 then
    LNumPredict := EnsureRange(FModelMaxContex, 512, LMaxContext)
  else
    LNumPredict := 512;

  LText :=  FModelTemplate;
  if LText.IsEmpty then
    LPrompt := BuildPrompt(FModel, AQuestion)
  else
    begin
    LText := LText.Replace('{role}', 'user');
    LText := LText.Replace('{content}', AQuestion);
    LPrompt := UTF8Encode(LText);
  end;

  LNumPrompt := -llama_tokenize(FModel, PUTF8Char(LPrompt), Length(LPrompt), nil, 0, true, true);

  SetLength(LPromptTokens, LNumPrompt);

  if llama_tokenize(FModel, PUTF8Char(LPrompt), Length(LPrompt), @LPromptTokens[0], Length(LPromptTokens), true, true) < 0 then
  begin
    SetError('Failed to tokenize prompt', []);
  end;

  LCtxParams := llama_context_default_params();
  LCtxParams.n_ctx := LNumPrompt + LNumPredict - 1;
  LCtxParams.n_batch := LNumPrompt;
  LCtxParams.no_perf := false;
  LCtxParams.n_threads := EnsureRange(FMaxThreads, 1, GetPhysicalProcessorCount());
  LCtxParams.n_threads_batch := LCtxParams.n_threads;

  LCtx := llama_new_context_with_model(FModel, LCtxParams);
  if LCtx = nil then
  begin
    SetError('Failed to create inference context', []);
    llama_free_model(FModel);
    exit;
  end;

  LSmplrParams := llama_sampler_chain_default_params();
  LSmplr := llama_sampler_chain_init(LSmplrParams);
  llama_sampler_chain_add(LSmplr, llama_sampler_init_greedy());

  LBatch := llama_batch_get_one(@LPromptTokens[0], Length(LPromptTokens));

  LNumPos := 0;

  FPerf := Default(TLumina.PerformanceResult);

  while LNumPos + LBatch.n_tokens < LNumPrompt + LNumPredict do
  begin
    if OnCancel() then
      Break;

    N := llama_decode(LCtx, LBatch);
    if N <> 0 then
    begin
      SetError('Failed to decode context', []);
      llama_sampler_free(LSmplr);
      llama_free(LCtx);
      llama_free_model(FModel);
      Exit;
    end;

    LNumPos := LNumPos + LBatch.n_tokens;

    LNewTokenId := llama_sampler_sample(LSmplr, LCtx, -1);
    if llama_token_is_eog(FModel, LNewTokenId) then
        break;

    LTokenStr := TokenToPiece(LCtx, LNewTokenId, false);
    if LFirstToken then
    begin
      LTokenStr := LTokenStr.Trim();
      LFirstToken := False;
    end;

    case FTokenResponse.AddToken(LTokenStr) of
      tpaWait:
      begin
      end;

      tpaAppend:
      begin
        OnNextToken(FTokenResponse.LastWord(False));
      end;

      tpaNewline:
      begin
        OnNextToken(#10);
        OnNextToken(FTokenResponse.LastWord(True));
      end;
    end;

    LBatch := llama_batch_get_one(@LNewTokenId, 1);
  end;

  FPerf := CalcPerformance(LCtx);

  llama_sampler_free(LSmplr);
  llama_free(LCtx);

  Result := True;
end;

function TLumina.GetPerformanceResult(): TLumina.PerformanceResult;
begin
  Result := FPerf;
end;

{$R Lumina.res}

var
  DepsDLLHandle: THandle = 0;
  DepsDLLFilename: string = '';

procedure UnloadDLL();
begin
  // unload deps DLL
  if DepsDLLHandle <> 0 then
  begin
    FreeLibrary(DepsDLLHandle);
    TFile.Delete(DepsDLLFilename);
    DepsDLLHandle := 0;
    DepsDLLFilename := '';
  end;
end;

function LoadDLL(var AError: string): Boolean;
var
  LResStream: TResourceStream;

  function e8d1523e85384e3fb9a50f12105ab26f(): string;
  const
    CValue = '3f087c82cfa24787b240dce0e4b39845';
  begin
    Result := CValue;
  end;

  procedure SetError(const AText: string);
  begin
    AError := AText;
  end;

begin
  Result := False;
  AError := 'Failed to load Deps DLL';

  // load deps DLL
  if DepsDLLHandle <> 0 then Exit(True);
  try
    if not ResourceExists(HInstance, PChar(e8d1523e85384e3fb9a50f12105ab26f)) then
    begin
      SetError('Failed to find Deps DLL resource');
      Exit;
    end;
    LResStream := TResourceStream.Create(HInstance, e8d1523e85384e3fb9a50f12105ab26f(), RT_RCDATA);
    try
      LResStream.Position := 0;
      DepsDLLFilename := TPath.Combine(TPath.GetTempPath,
        TPath.ChangeExtension(TPath.GetGUIDFileName.ToLower, '.'));
      if not HasEnoughDiskSpace(TPath.GetDirectoryName(DepsDLLFilename), LResStream.Size) then
      begin
        AError := 'Not enough disk space to extract the Deps DLL';
        Exit;
      end;

      LResStream.SaveToFile(DepsDLLFilename);
      if not TFile.Exists(DepsDLLFilename) then
      begin
        SetError('Failed to find extracted Deps DLL');
        Exit;
      end;
      DepsDLLHandle := LoadLibrary(PChar(DepsDLLFilename));
      if DepsDLLHandle = 0 then
      begin
        SetError('Failed to load extracted Deps DLL: ' + SysErrorMessage(GetLastError));
        Exit;
      end;

      GetExports(DepsDLLHandle);

      Result := True;
    finally
      LResStream.Free();
    end;
  except
    on E: Exception do
      SetError('Unexpected error: ' + E.Message);
  end;
end;

{$ENDREGION}

{$REGION ' Unit Init & Fini '}

var
  LError: string;
  
initialization
begin
  ReportMemoryLeaksOnShutdown := True;

  SetConsoleCP(CP_UTF8);
  SetConsoleOutputCP(CP_UTF8);
  EnableVirtualTerminalProcessing();  

  if not LoadDLL(LError) then
  begin
    MessageBox(0, PChar(LError), 'Critical Initialization Error', MB_ICONERROR);
    Halt(1); // Exit the application with a non-zero exit code to indicate failure
  end;

end;

finalization
begin
  try
    UnloadDLL();
  except
    on E: Exception do
    begin
      MessageBox(0, PChar(E.Message), 'Critical Shutdown Error', MB_ICONERROR);
    end;
  end;
end;
{$ENDREGION}

end.
