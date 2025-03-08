import os
import sys
import logging
import pdfplumber
import numpy as np
import pandas as pd
import joblib
import streamlit as st
from datetime import datetime
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import cosine_similarity
import torch
import re
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.manifold import TSNE
import nltk
from concurrent.futures import ThreadPoolExecutor
import warnings
from pathlib import Path
from typing import List, Tuple, Dict, Any, Optional, Union
import tempfile
import base64

# Suppress Hugging Face symlinks warning
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"

# Set page configuration
st.set_page_config(
    page_title="Resume Analyzer",
    page_icon="📄",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("resume_analyzer.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger("ResumeAnalyzer")

# Initialize NLTK resources
@st.cache_resource
def initialize_nltk():
    try:
        nltk.download('stopwords', quiet=True)
        nltk.download('punkt', quiet=True)
        logger.info("NLTK resources initialized successfully")
        return stopwords.words("english")
    except Exception as e:
        logger.error(f"Error initializing NLTK resources: {e}")
        st.error(f"Error initializing NLTK resources: {e}")
        raise

# Initialize transformers model
@st.cache_resource
def initialize_model(model_name='distilbert-base-uncased'):
    try:
        # Import here to avoid unnecessary loading if transformers aren't used
        from transformers import AutoTokenizer, AutoModel
        
        # Suppress specific transformers warnings
        warnings.filterwarnings("ignore", category=UserWarning, 
                               message="The cached_file")
        
        with st.spinner(f"Loading {model_name} model..."):
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModel.from_pretrained(model_name)
            
            # Move model to GPU if available
            if torch.cuda.is_available():
                model = model.to('cuda')
                st.success("Model loaded on GPU")
            else:
                st.success("Model loaded on CPU")
                
        return tokenizer, model
            
    except Exception as e:
        logger.error(f"Error loading transformer model: {e}")
        st.warning(f"Error loading transformer model: {e}. Falling back to TF-IDF only.")
        return None, None


class ResumeAnalyzer:

    
    def __init__(self, resume_files, job_description: str, model_name: str = 'distilbert-base-uncased'):

        self.resume_files = resume_files
        self.job_description = job_description
        self.model_name = model_name
        self.resumes: List[str] = []
        self.resume_names: List[str] = []
        self.stop_words = initialize_nltk()
        self.tokenizer = None
        self.model = None
        self.vectorizer = None
        self.results = None
        self.tfidf_results = None
        self.transformer_results = None
        self.use_transformers = True
        

        self.output_folder = Path(f"resume_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        self.output_folder.mkdir(exist_ok=True)
    
    def _extract_text_from_pdf(self, pdf_file) -> str:

        text = ""
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp_file:
                tmp_file.write(pdf_file.read())
                tmp_path = tmp_file.name
            
            with pdfplumber.open(tmp_path) as pdf:
                for page in pdf.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + " "
            
             
            os.unlink(tmp_path)
            
            return text.lower().strip()
        except Exception as e:
            logger.error(f"Error reading {pdf_file.name}: {e}")
            return ""
    
    def _preprocess_text(self, text: str) -> str:

        
        text = re.sub(r'[^\w\s]', ' ', text)
        text = re.sub(r'\s+', ' ', text).strip()
        
        
        words = word_tokenize(text)
        filtered_words = [word for word in words if word.isalnum() and word not in self.stop_words]
        
        return " ".join(filtered_words)
    
    def _initialize_model(self) -> bool:

        self.tokenizer, self.model = initialize_model(self.model_name)
        return self.tokenizer is not None and self.model is not None
    
    def _get_transformer_embedding(self, text: str) -> np.ndarray:

        try:
            
            tokens = self.tokenizer(
                text, 
                padding=True, 
                truncation=True, 
                max_length=512, 
                return_tensors="pt"
            )
            
            
            if torch.cuda.is_available():
                tokens = {key: val.to('cuda') for key, val in tokens.items()}
            
    
            with torch.no_grad():
                outputs = self.model(**tokens)
            
            
            embeddings = outputs.last_hidden_state[:, 0].cpu().numpy()
            return embeddings
        except Exception as e:
            logger.error(f"Error generating embeddings: {e}")
            return np.zeros((1, 768))  
    
    def load_resumes(self, progress_bar=None) -> int:

        logger.info(f"Loading {len(self.resume_files)} resumes")
        
        if not self.resume_files:
            logger.error("No resume files provided")
            raise ValueError("No resume files provided")
        
        
        self.resumes = []
        self.resume_names = []
        
        
        for i, file in enumerate(self.resume_files):
            if progress_bar:
                progress_bar.progress((i + 1) / len(self.resume_files))
                
            text = self._extract_text_from_pdf(file)
            if text:
                self.resumes.append(text)
                self.resume_names.append(file.name)
            else:
                logger.warning(f"No text extracted from {file.name}")
        
        logger.info(f"Successfully loaded {len(self.resumes)} resumes")
        
        
        logger.info("Preprocessing resume texts")
        self.resumes = [self._preprocess_text(resume) for resume in self.resumes]
        self.job_description = self._preprocess_text(self.job_description)
        
        return len(self.resumes)
    
    def analyze_with_tfidf(self) -> Tuple[pd.DataFrame, List[Tuple[str, float]]]:

        logger.info("Analyzing resumes with TF-IDF")
        
        
        self.vectorizer = TfidfVectorizer(ngram_range=(1, 2), max_features=5000)
        all_docs = self.resumes + [self.job_description]
        tfidf_matrix = self.vectorizer.fit_transform(all_docs)
        
        
        job_vector = tfidf_matrix[-1]
        resume_vectors = tfidf_matrix[:-1]
        
        
        similarities = cosine_similarity(resume_vectors, job_vector).flatten()
        
        
        feature_names = np.array(self.vectorizer.get_feature_names_out())
        job_keywords = self._extract_important_keywords(job_vector, feature_names)
        
        
        self.tfidf_results = pd.DataFrame({
            "Resume": self.resume_names,
            "TF-IDF Similarity": similarities,
            "ATS Score": (similarities * 100).round(2)
        })
        
        
        if len(self.resumes) > 1:
            num_clusters = min(3, len(self.resumes))
            kmeans = KMeans(n_clusters=num_clusters, random_state=42, n_init=10)
            cluster_labels = kmeans.fit_predict(resume_vectors)
            self.tfidf_results["Cluster"] = cluster_labels
        
        
        self.tfidf_results = self.tfidf_results.sort_values(
            by="TF-IDF Similarity", 
            ascending=False
        )
        
        return self.tfidf_results, job_keywords
    
    def analyze_with_transformer(self) -> Optional[pd.DataFrame]:

        if not self.tokenizer or not self.model:
            if not self._initialize_model():
                logger.warning("Skipping transformer analysis due to model initialization failure")
                return None
        
        logger.info(f"Analyzing resumes with {self.model_name}")
        
        
        with st.spinner("Creating embeddings for resumes..."):
            resume_embeddings = []
            for resume in self.resumes:
                resume_embeddings.append(self._get_transformer_embedding(resume))
            
            resume_embeddings = np.vstack(resume_embeddings)
            job_embedding = self._get_transformer_embedding(self.job_description)
        
        
        similarities = cosine_similarity(resume_embeddings, job_embedding).flatten()
        
        
        self.transformer_results = pd.DataFrame({
            "Resume": self.resume_names,
            "Transformer Similarity": similarities,
            "Transformer Score": (similarities * 100).round(2)
        })
        
        
        self.transformer_results = self.transformer_results.sort_values(
            by="Transformer Similarity", 
            ascending=False
        )
        
        return self.transformer_results
    
    def _extract_important_keywords(
        self, 
        vector, 
        feature_names: np.ndarray, 
        top_n: int = 20
    ) -> List[Tuple[str, float]]:

        
        indices = vector.toarray().argsort()[0, -top_n:][::-1]
        
        
        top_keywords = [(feature_names[i], vector[0, i]) for i in indices]
        
        return top_keywords
    
    def combine_results(self) -> Optional[pd.DataFrame]:

        if hasattr(self, 'tfidf_results') and hasattr(self, 'transformer_results') and self.transformer_results is not None:
            
            combined = pd.merge(
                self.tfidf_results, 
                self.transformer_results,
                on="Resume"
            )
            
            
            combined["Combined Score"] = (
                (combined["ATS Score"] + combined["Transformer Score"]) / 2
            ).round(2)
            
            
            combined = combined.sort_values(by="Combined Score", ascending=False)
            self.results = combined
            
        elif hasattr(self, 'tfidf_results'):
            self.results = self.tfidf_results
            
        elif hasattr(self, 'transformer_results') and self.transformer_results is not None:
            self.results = self.transformer_results
            
        else:
            logger.error("No analysis results available")
            return None
        
        
        output_path = self.output_folder / "resume_analysis_results.csv"
        self.results.to_csv(output_path, index=False)
        logger.info(f"Results saved to {output_path}")
        
        return self.results
    
    def visualize_results(self) -> Tuple[plt.Figure, Optional[plt.Figure]]:

        if self.results is None:
            logger.error("No results available for visualization")
            return None, None
        
        
        logger.info("Creating visualizations")
        
        try:
            # 1. Bar chart of top resumes by score
            fig1 = plt.figure(figsize=(12, 8))
            top_n = min(10, len(self.results))
            
            if "Combined Score" in self.results.columns:
                score_col = "Combined Score"
            elif "ATS Score" in self.results.columns:
                score_col = "ATS Score"
            else:
                score_col = "Transformer Score"
            
            
            top_resumes = self.results.head(top_n)
            
            
            top_resumes_plot = top_resumes.copy()
            top_resumes_plot["Resume"] = top_resumes_plot["Resume"].apply(
                lambda x: x[:25] + "..." if len(x) > 25 else x
            )
            
            
            plt.barh(
                top_resumes_plot["Resume"],
                top_resumes_plot[score_col],
                color=sns.color_palette("viridis", top_n)
            )
            plt.title(f"Top {top_n} Resumes by {score_col}")
            plt.xlabel("Score")
            plt.ylabel("Resume")
            plt.tight_layout()
            
            
            fig2 = None
            if (hasattr(self, 'tfidf_results') and "Cluster" in self.tfidf_results.columns 
                and len(self.resumes) >= 3 and hasattr(self, 'vectorizer')):
                
                tfidf_matrix = self.vectorizer.transform(self.resumes)
                
                
                perplexity = min(30, max(5, len(self.resumes) // 2))  
                tsne = TSNE(n_components=2, random_state=42, perplexity=perplexity)
                reduced_data = tsne.fit_transform(tfidf_matrix.toarray())
                
                
                fig2 = plt.figure(figsize=(10, 8))
                
                
                clusters = self.tfidf_results["Cluster"].values
                unique_clusters = np.unique(clusters)
                
            
                for cluster in unique_clusters:
                    indices = np.where(clusters == cluster)[0]
                    plt.scatter(
                        reduced_data[indices, 0],
                        reduced_data[indices, 1],
                        label=f"Cluster {cluster}",
                        alpha=0.7
                    )
                
                
                for i, name in enumerate(self.resume_names):
                    short_name = Path(name).stem[:15]
                    plt.annotate(
                        short_name,
                        (reduced_data[i, 0], reduced_data[i, 1]),
                        fontsize=8
                    )
                
                plt.title("Resume Clusters")
                plt.legend()
                plt.tight_layout()
                
            logger.info("Visualizations created successfully")
            return fig1, fig2
            
        except Exception as e:
            logger.error(f"Error creating visualizations: {e}")
            st.error(f"Error creating visualizations: {e}")
            return None, None
    
    def extract_missing_keywords(self, resume_idx: int) -> List[Tuple[str, float]]:

        if not hasattr(self, 'vectorizer') or self.vectorizer is None:
            logger.error("TF-IDF vectorizer not available")
            return []
        
        
        feature_names = self.vectorizer.get_feature_names_out()
        
        
        all_docs = self.resumes + [self.job_description]
        tfidf_matrix = self.vectorizer.transform(all_docs)
        job_vector = tfidf_matrix[-1]
        
        
        resume_vector = tfidf_matrix[resume_idx]
        
        
        job_keywords = self._extract_important_keywords(job_vector, feature_names, top_n=30)
        
        
        missing_keywords = []
        for keyword, importance in job_keywords:
            if resume_vector[0, self.vectorizer.vocabulary_[keyword]] == 0:
                missing_keywords.append((keyword, importance))
        
        return missing_keywords
    
    def run_full_analysis(self, progress_bar=None) -> Optional[pd.DataFrame]:

        num_resumes = self.load_resumes(progress_bar)
        if num_resumes == 0:
            logger.error("No valid resumes found")
            return None
        
        
        with st.spinner("Running TF-IDF analysis..."):
            tfidf_results, job_keywords = self.analyze_with_tfidf()
        
        
        transformer_results = None
        if self.use_transformers:
            try:
                with st.spinner("Running transformer analysis..."):
                    transformer_results = self.analyze_with_transformer()
            except Exception as e:
                logger.error(f"Transformer analysis failed: {e}")
                st.warning("Transformer analysis failed. Continuing with TF-IDF results only.")
        
        
        combined_results = self.combine_results()
        
        return combined_results, job_keywords



def get_csv_download_link(df, filename="results.csv", text="Download CSV"):
    csv = df.to_csv(index=False)
    b64 = base64.b64encode(csv.encode()).decode()
    href = f'<a href="data:file/csv;base64,{b64}" download="{filename}">{text}</a>'
    return href



def main():
    st.title("📄 Resume Analyzer")
    st.markdown("### Match resumes to job descriptions using AI")
    
    
    st.sidebar.title("Options")
    
    
    default_job_description = """
Job Title: Python Developer Intern (Remote)

About Us: We are an innovative tech company focused on delivering cutting-edge solutions to a wide range of industries.

Responsibilities:
- Assist in developing and maintaining Python applications, scripts, and modules.
- Write clean, efficient, and well-documented code.
- Collaborate with team members to troubleshoot, debug, and resolve software defects.
- Contribute to the design and implementation of new features and functionality.

Requirements:
- Currently pursuing or recently completed a degree in Computer Science, Software Engineering, or a related field.
- Basic knowledge of Python programming and its libraries (e.g., Pandas, Flask, Django, etc.).
- Familiarity with Git or other version control systems.
- Strong problem-solving skills and a keen eye for detail.
- Good communication skills in English (both written and verbal).

Preferred Skills:
- Familiarity with web development frameworks such as Django or Flask.
- Experience with databases like MySQL, PostgreSQL, or MongoDB.
- Understanding of REST APIs and web services.
- Knowledge of front-end technologies (HTML, CSS, JavaScript) is a plus.
    """
    
    
    try:
        import transformers
        transformers_available = True
    except ImportError:
        transformers_available = False
    
    
    use_transformers = st.sidebar.checkbox(
        "Use transformer model (better but slower)",
        value=transformers_available,
        disabled=not transformers_available
    )
    
    if not transformers_available and use_transformers:
        st.sidebar.warning("Transformers library not detected. Install with: pip install transformers")
    
    
    show_advanced = st.sidebar.checkbox("Show advanced options", value=False)
    
    if show_advanced:
        model_name = st.sidebar.selectbox(
            "Transformer model",
            ["distilbert-base-uncased", "bert-base-uncased"],
            disabled=not use_transformers
        )
    else:
        model_name = "distilbert-base-uncased"
    
    
    tab1, tab2, tab3 = st.tabs(["Upload & Analyze", "Results", "Detailed Analysis"])
    
    with tab1:
        st.markdown("## Upload Resumes")
        st.markdown("Upload one or more resumes in PDF format:")
        
        uploaded_files = st.file_uploader(
            "Choose PDF files",
            type=["pdf"],
            accept_multiple_files=True
        )
        
        st.markdown("## Job Description")
        job_description_option = st.radio(
            "Job Description Source",
            ["Use example", "Enter custom"]
        )
        
        if job_description_option == "Use example":
            job_description = default_job_description
            st.text_area("Example Job Description", job_description, height=250, disabled=True)
        else:
            job_description = st.text_area(
                "Enter Job Description",
                height=250,
                placeholder="Paste job description here..."
            )
        
        analyze_button = st.button("Analyze Resumes", type="primary", disabled=not (uploaded_files and job_description))
        
        
        if "results" not in st.session_state:
            st.session_state.results = None
            st.session_state.job_keywords = None
            st.session_state.bar_chart = None
            st.session_state.cluster_chart = None
        
        if analyze_button and uploaded_files and job_description:
            progress_bar = st.progress(0)
            
            with st.spinner("Analyzing resumes..."):
                try:
                    
                    analyzer = ResumeAnalyzer(uploaded_files, job_description, model_name)
                    analyzer.use_transformers = use_transformers
                    
                    
                    results, job_keywords = analyzer.run_full_analysis(progress_bar)
                    
                    if results is not None:
                        st.session_state.results = results
                        st.session_state.job_keywords = job_keywords
                        
                        
                        st.session_state.bar_chart, st.session_state.cluster_chart = analyzer.visualize_results()
                        
                        st.success(f"Analysis completed successfully! {len(uploaded_files)} resume(s) analyzed.")
                        st.balloons()
                        
                        
                        st.rerun()
                    else:
                        st.error("Analysis failed. No results available.")
                
                except Exception as e:
                    st.error(f"Analysis failed: {str(e)}")
                    logger.error(f"Analysis failed: {e}", exc_info=True)
                
                finally:
                    progress_bar.empty()
    
    with tab2:
        if st.session_state.results is not None:
            st.markdown("## Analysis Results")
            
            results = st.session_state.results
            
        
            if "Combined Score" in results.columns:
                score_col = "Combined Score"
            elif "ATS Score" in results.columns:
                score_col = "ATS Score"
            else:
                score_col = "Transformer Score"
            
            
            st.markdown(f"### Top Resumes by {score_col}")
            st.dataframe(
                results[["Resume", score_col]].head(10),
                hide_index=True,
                use_container_width=True
            )
            
            
            if st.session_state.bar_chart:
                st.markdown("### Visual Comparison")
                st.pyplot(st.session_state.bar_chart)
            
            
            if st.session_state.cluster_chart:
                st.markdown("### Resume Clusters")
                st.pyplot(st.session_state.cluster_chart)
            
            
            st.markdown("### Download Results")
            st.markdown(
                get_csv_download_link(results, "resume_analysis_results.csv", "📥 Download Complete Results"),
                unsafe_allow_html=True
            )
        else:
            st.info("No analysis results yet. Go to the 'Upload & Analyze' tab to get started.")
    
    with tab3:
        if st.session_state.results is not None and st.session_state.job_keywords is not None:
            st.markdown("## Detailed Analysis")
            
            
            st.markdown("### Top Job Keywords")
            
            
            keywords_df = pd.DataFrame(
                st.session_state.job_keywords[:15],
                columns=["Keyword", "Importance"]
            )
            
            
            fig, ax = plt.subplots(figsize=(10, 6))
            sns.barplot(
              x="Importance",
              y="Keyword",
              hue="Keyword",  
              data=keywords_df,
              palette="viridis",
              ax=ax,
              legend=False    
            )
            ax.set_title("Top Job Keywords by Importance")
            st.pyplot(fig)
            
            
            st.markdown("### Individual Resume Analysis")
            
            results = st.session_state.results
            selected_resume = st.selectbox(
                "Select a resume for detailed analysis",
                options=results["Resume"].tolist()
            )
            
            if selected_resume:
                resume_idx = list(results["Resume"]).index(selected_resume)
                
                
                resume_row = results[results["Resume"] == selected_resume].iloc[0]
                
                score_cols = [col for col in resume_row.index if "Score" in col or "Similarity" in col]
                scores = {col: resume_row[col] for col in score_cols}
                
                col1, col2 = st.columns(2)
                
                with col1:
                    st.markdown("#### Resume Information")
                    st.markdown(f"**Filename:** {selected_resume}")
                    
                    for col, score in scores.items():
                        if "Score" in col:
                            st.markdown(f"**{col}:** {score:.2f}/100")
                        else:
                            st.markdown(f"**{col}:** {score:.4f}")
                
                
                try:
                    
                    analyzer = ResumeAnalyzer([], "", model_name)
                    analyzer.vectorizer = TfidfVectorizer()
                    analyzer.vectorizer.vocabulary_ = {k: i for i, k in enumerate(st.session_state.job_keywords)}
                    
                    with col2:
                        st.markdown("#### Suggested Improvements")
                        st.markdown("Important keywords from the job description that may be missing:")
                        
                        
                        for keyword, _ in st.session_state.job_keywords[:8]:
                            st.markdown(f"- {keyword}")
                except Exception as e:
                    logger.error(f"Error displaying missing keywords: {e}")
        else:
            st.info("No analysis results yet. Go to the 'Upload & Analyze' tab to get started.")


if __name__ == "__main__":
    main()