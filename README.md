![Lumina](media/lumina.png)  
[![Chat on Discord](https://img.shields.io/discord/754884471324672040?style=for-the-badge)](https://discord.gg/tPWjMwK)
[![Follow on Bluesky](https://img.shields.io/badge/Bluesky-tinyBigGAMES-blue?style=for-the-badge&logo=bluesky)](https://bsky.app/profile/tinybiggames.com)

# 🌟 Lumina: Advanced Local Generative AI for Delphi Developers 💻🤖

Lumina offers a cutting-edge 🛠️ for Delphi developers to seamlessly integrate advanced generative AI capabilities into their 📱. Built on the computational backbone of **llama.cpp** 🐪, Lumina prioritizes data privacy 🔒, performance ⚡, and a user-friendly API 📚, making it a powerful tool for local AI inference 🤖.

## 🧐 Why Choose Lumina?

- **Localized Processing** 🏠: Operates entirely offline, ensuring sensitive data remains confidential 🛡️ while offering complete computational control 🧠.
- **Broad Model Compatibility** 🌐: Supports **GGUF models** compliant with llama.cpp standards, granting access to diverse AI architectures 🧩.
- **Intuitive Development Interface** 🎛️: A concise, flexible API simplifies model management 🗂️, inference execution 🧮, and callback customization 🎚️, minimizing implementation complexity.
- **Future-Ready Scalability** 🚀: This release emphasizes stability 🏗️ and foundational features, with plans for multi-turn conversation 💬 and retrieval-augmented generation (RAG) 🔍 in future updates.

## 🛠️ Key Functionalities

### 🤖 Advanced AI Integration

Lumina expands your development toolkit 🎒 with capabilities such as:
- Dynamic chatbot creation 💬.
- Automated text generation 📝 and summarization 📰.
- Context-sensitive content generation ✍️.
- Real-time inference for adaptive processes ⚡.

### 🔒 Privacy-Driven AI Execution

- Operates independently of external networks 🛡️, guaranteeing data security.
- Uses Vulkan 🖥️ for optional GPU acceleration to enhance performance.

### ⚙️ Performance Optimization

- Configurable GPU utilization through the `AGPULayers` parameter 🧩.
- Dynamic thread allocation based on hardware capabilities 🖥️ via `AMaxThreads`.
- Comprehensive performance metrics 📊, offering insights into throughput 📈 and efficiency.

### 🔗 Streamlined Integration

- Embedded dependencies eliminate the need for external libraries 📦.
- Lightweight architecture (~2.5MB overhead) ensures broad deployment compatibility 🌍.

## 📥 Installation

1. **Download the Repository** 📦
   - [Download here](https://github.com/tinyBigGAMES/Lumina/archive/refs/heads/main.zip) and extract the files to your preferred directory 📂.

2. **Acquire a GGUF Model** 🧠
   - Obtain a model from [Hugging Face](https://huggingface.co), such as [Gemma 2.2B GGUF (Q8_0)](https://huggingface.co/bartowski/gemma-2-2b-it-abliterated-GGUF/resolve/main/gemma-2-2b-it-abliterated-Q8_0.gguf?download=true). Save it to a directory accessible to your application (e.g., `C:/LLM/GGUF`) 💾.

3. **Ensure GPU Compatibility** 🎮
   - Verify Vulkan compatibility for enhanced performance ⚡. Adjust `AGPULayers` as needed to accommodate VRAM limitations 📉.

4. **✨ TLumina Class** 
   - 📜 Add `Lumina` to your `uses` section.  
   - 🛠️ Create an instance of `TLumina`.  
   - 🚀 All functionality will then be at your disposal. That simple! 🎉

5. **Explore Examples** 🔍
   - Check the `examples` directory for detailed usage demonstrations 📚.

## 🛠️ Usage

### 🔧 Basic Setup

Integrate Lumina into your Delphi project 🖥️:

```delphi
var
  Lumina: TLumina;
begin
  Lumina := TLumina.Create;
  try
    if Lumina.LoadModel('C:\LLM\GGUF\gemma-2-2b-it-abliterated-Q8_0.gguf',
      '', 8192, -1, 8) then
    begin
      if Lumina.SimpleInference('What is the capital of Italy?') then
        WriteLn('Inference completed successfully.')
      else
        WriteLn('Error: ', Lumina.GetError);
    end;
  finally
    Lumina.Free;
  end;
end;
```

### 🎚️ Customizing Callbacks

Define custom behavior using Lumina’s callback functions 🛠️:

```delphi
procedure NextTokenCallback(const AToken: string; const AUserData: Pointer);
begin
  Write(AToken);
end;

Lumina.SetNextTokenCallback(NextTokenCallback, nil);
```

## 📖 API Reference

### 🧩 Core Methods

- **LoadModel** 📂
  - Parameters:
    - `AModelFilename`: Path to the GGUF model file 📄.
    - `ATemplate`: Optional inference template 📝.
    - `AMaxContext`: Maximum context size (default: 512) 🧠.
    - `AGPULayers`: GPU layer configuration (-1 for maximum) 🎮.
    - `AMaxThreads`: Number of CPU threads allocated 🖥️.
  - Returns a boolean indicating success ✅.

- **SimpleInference** 🧠
  - Accepts a single query for immediate processing 📝.
  - Returns a boolean indicating success ✅.

- **SetNextTokenCallback** 💬
  - Assigns a handler to process tokens during inference 🧩.

- **UnloadModel** ❌
  - Frees resources allocated during model loading 🗑️.

- **GetPerformanceResult** 📊
  - Provides metrics, including token generation rates 📈.

## 🛠️ Advanced Configurations

### 🧠 Custom Inference Templates

Lumina will use the template defined in the model's meta data by default, but you can also define custom templates to match your model’s requirements or change its behavor. These are some common model templates ✍️:

```delphi
const
  CHATML_TEMPLATE = '<|im_start|>{role} {content}<|im_end|><|im_start|>assistant';
  GEMMA_TEMPLATE  = '<start_of_turn>{role} {content}<end_of_turn>';
  PHI_TEMPLATE    = '<|{role}|> {content}<|end|><|assistant|>';
```

- **{role}** - will be replaced with the role (user, assistant, etc.)
- **{content}** - will be replaced with the content sent to the model

### 🎮 GPU Optimization

- `AGPULayers` values:
  - `-1`: Utilize all available layers (default) 🖥️.
  - `0`: CPU-only processing 🖥️.
  - Custom values for partial GPU utilization 🎛️.

### 📊 Performance Metrics

Retrieve detailed operational metrics 📈:

```delphi
var
  Perf: TLumina.PerformanceResult;
begin
  Perf := Lumina.GetPerformanceResult;
  WriteLn('Tokens/Sec: ', Perf.TokensPerSecond);
  WriteLn('Input Tokens: ', Perf.TotalInputTokens);
  WriteLn('Output Tokens: ', Perf.TotalOutputTokens);
end;
```

## 🎙️ Media  

### 🌊 Deep Dive Podcast  
Discover in-depth discussions and insights about **Lumina** and its innovative features. 🚀✨

https://github.com/user-attachments/assets/165e3dee-b29f-4478-b9ef-4fb6d2df2485


### 🛠️ Support and Resources

- Report issues via the [Issue Tracker](https://github.com/tinyBigGAMES/Lumina/issues) 🐞.
- Engage in discussions on the [Forum](https://github.com/tinyBigGAMES/Lumina/discussions) and [Discord](https://discord.gg/tPWjMwK) 💬.
- Learn more at [Learn Delphi](https://learndelphi.org) 📚.

### 🤝 Contributing  

Contributions to **✨ Lumina** are highly encouraged! 🌟  
- 🐛 **Report Issues:** Submit issues if you encounter bugs or need help.  
- 💡 **Suggest Features:** Share your ideas to make **Lumina** even better.  
- 🔧 **Create Pull Requests:** Help expand the capabilities and robustness of the library.  

Your contributions make a difference! 🙌✨

#### Contributors 👥🤝
<br/>

<a href="https://github.com/tinyBigGAMES/Lumina/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=tinyBigGAMES/Lumina&max=500&columns=20&anon=1" />
</a>

### 📜 Licensing

**Lumina** is distributed under the 🆓 **BSD-3-Clause License**, allowing for redistribution and use in both source and binary forms, with or without modification, under specific conditions. See the [LICENSE](https://github.com/tinyBigGAMES/Lumina?tab=BSD-3-Clause-1-ov-file#BSD-3-Clause-1-ov-file) file for more details.

---

Advance your Delphi applications with Lumina 🌟 – a sophisticated solution for integrating local generative AI 🤖.

<p align="center">
<img src="media/delphi.png" alt="Delphi">
</p>
<h5 align="center">

Made with :heart: in Delphi
</h5>

