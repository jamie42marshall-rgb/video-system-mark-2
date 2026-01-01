# Use specific version of nvidia cuda image
# FROM wlsdml1114/my-comfy-models:v1 as model_provider
FROM wlsdml1114/multitalk-base:1.7 as runtime
RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client
WORKDIR /
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd /ComfyUI && \
    pip install -r requirements.txt

# Install WanVideoWrapper early (moved up for organization)
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt

# Now install other custom nodes
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    cd ComfyUI-GGUF && \
    pip install -r requirements.txt
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    cd ComfyUI-KJNodes && \
    pip install -r requirements.txt
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kael558/ComfyUI-GGUF-FantasyTalking && \
    cd ComfyUI-GGUF-FantasyTalking && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap
    
# Clone IntelligentVRAMNode with retry
RUN cd /ComfyUI/custom_nodes && \
    (git clone https://github.com/eddyhhlure1Eddy/IntelligentVRAMNode || \
     (echo "First attempt failed, retrying in 5 seconds..." && sleep 5 && \
      git clone https://github.com/eddyhhlure1Eddy/IntelligentVRAMNode))

# Clone auto_wan2.2animate_freamtowindow_server with retry
RUN cd /ComfyUI/custom_nodes && \
    (git clone https://github.com/eddyhhlure1Eddy/auto_wan2.2animate_freamtowindow_server || \
     (echo "First attempt failed, retrying in 5 seconds..." && sleep 5 && \
      git clone https://github.com/eddyhhlure1Eddy/auto_wan2.2animate_freamtowindow_server))

# Clone ComfyUI-AdaptiveWindowSize with retry and fix nested structure
RUN cd /ComfyUI/custom_nodes && \
    (git clone https://github.com/eddyhhlure1Eddy/ComfyUI-AdaptiveWindowSize || \
     (echo "First attempt failed, retrying in 5 seconds..." && sleep 5 && \
      git clone https://github.com/eddyhhlure1Eddy/ComfyUI-AdaptiveWindowSize)) && \
    cd ComfyUI-AdaptiveWindowSize && \
    mv ComfyUI-AdaptiveWindowSize/* . && \
    mv ComfyUI-AdaptiveWindowSize/.* . 2>/dev/null || true && \
    rmdir ComfyUI-AdaptiveWindowSize

# Fix SageAttention AFTER all custom nodes are installed (prevents other nodes from overwriting)
# Force version 1.0.6 - last stable PyPI release, avoids broken SM90 kernel in 2.x betas
RUN echo "=== SAGE ATTENTION FIX ===" && \
    echo "Uninstalling any existing version..." && \
    (pip uninstall sageattention -y 2>/dev/null || echo "Nothing to uninstall") && \
    echo "Installing stable version 1.0.6..." && \
    pip install --no-cache-dir sageattention==1.0.6 && \
    echo "=== INSTALLED VERSION ===" && \
    pip show sageattention || echo "Install may have failed"
    
RUN wget -q https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors -O /ComfyUI/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors
RUN wget -q https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors -O /ComfyUI/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors
RUN wget -q https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors -O /ComfyUI/models/clip_vision/clip_vision_h.safetensors
RUN wget -q https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_bf16.safetensors -O /ComfyUI/models/text_encoders/nsfw_wan_umt5-xxl_bf16.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors -O /ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors
COPY . .
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
