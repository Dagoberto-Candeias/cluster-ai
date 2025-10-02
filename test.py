import streamlit as st
import os
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import FAISS
from langchain.chains import RetrievalQA
from langchain.llms import HuggingFacePipeline
from transformers import pipeline

# Set page config
st.set_page_config(page_title="PDF Summarization Tool", page_icon="📄", layout="wide")

# Title
st.title("📄 PDF Summarization Tool")
st.markdown("Upload a PDF and get an AI-powered summary using LangChain, FAISS, and Sentence Transformers.")

# Sidebar for configuration
st.sidebar.header("Configuration")
model_name = st.sidebar.selectbox(
    "Select Embedding Model",
    ["sentence-transformers/all-MiniLM-L6-v2", "sentence-transformers/all-mpnet-base-v2"],
    index=0
)

chunk_size = st.sidebar.slider("Chunk Size", 500, 2000, 1000)
chunk_overlap = st.sidebar.slider("Chunk Overlap", 0, 500, 200)

# File uploader
uploaded_file = st.file_uploader("Choose a PDF file", type="pdf")

if uploaded_file is not None:
    # Save uploaded file temporarily
    with open("temp.pdf", "wb") as f:
        f.write(uploaded_file.getvalue())

    try:
        # Load PDF
        with st.spinner("Loading PDF..."):
            loader = PyPDFLoader("temp.pdf")
            documents = loader.load()

        st.success(f"PDF loaded successfully! {len(documents)} pages found.")

        # Split text
        with st.spinner("Splitting text into chunks..."):
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=chunk_size,
                chunk_overlap=chunk_overlap
            )
            texts = text_splitter.split_documents(documents)

        st.info(f"Text split into {len(texts)} chunks.")

        # Create embeddings
        with st.spinner("Creating embeddings..."):
            embeddings = HuggingFaceEmbeddings(model_name=model_name)
            vectorstore = FAISS.from_documents(texts, embeddings)

        st.success("Embeddings created and stored in FAISS vector store.")

        # Create QA chain
        with st.spinner("Setting up summarization pipeline..."):
            # Use a smaller model for summarization
            summarizer = pipeline("summarization", model="facebook/bart-large-cnn")
            llm = HuggingFacePipeline(pipeline=summarizer)

            qa_chain = RetrievalQA.from_chain_type(
                llm=llm,
                chain_type="stuff",
                retriever=vectorstore.as_retriever(search_kwargs={"k": 5})
            )

        # Query input
        query = st.text_area(
            "Enter your summarization query:",
            value="Summarize the main points of this document.",
            height=100
        )

        if st.button("Generate Summary"):
            with st.spinner("Generating summary..."):
                result = qa_chain.run(query)

            st.subheader("Summary:")
            st.write(result)

            # Show relevant chunks
            st.subheader("Relevant Text Chunks:")
            docs = vectorstore.similarity_search(query, k=3)
            for i, doc in enumerate(docs):
                with st.expander(f"Chunk {i+1}"):
                    st.write(doc.page_content)

    except Exception as e:
        st.error(f"An error occurred: {str(e)}")

    finally:
        # Clean up temp file
        if os.path.exists("temp.pdf"):
            os.remove("temp.pdf")

else:
    st.info("Please upload a PDF file to get started.")

# Footer
st.markdown("---")
st.markdown("Built with Streamlit, LangChain, FAISS, and Hugging Face Transformers.")
