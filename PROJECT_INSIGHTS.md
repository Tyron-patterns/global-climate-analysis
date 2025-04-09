## 🔍 Summary for Decision-Makers and General Audience

### 📌 TL;DR  
This project analyzes global climate data to measure warming trends and temperature variability since the 18th century. Key findings include a ~2.1°C global temperature increase and rising climate instability, especially in the Northern Hemisphere. Insights are based on SQL-driven analysis and visualized through Power BI.

---

### 🌡️ Climate Insights
- **Global temperatures have increased by ~2.11°C**, with the **hottest years** all occurring in the **last two decades**.
- The **Northern Hemisphere**—especially **North America, Europe, and Asia**—is experiencing the **fastest warming**, likely driven by phenomena such as **Arctic amplification**.
- While **Africa, South America, and Australia** show slower warming, their **high baseline temperatures** and exposure to heat-related risks make them especially vulnerable.
- Year-to-year **temperature variability** is also rising, often in the same regions with the strongest warming. This supports concerns about the **increased frequency and unpredictability of extreme weather events**.

---

### 🛠️ Technical Takeaways
- **IQR filtering** improved data reliability at the global level by removing outliers, resulting in clearer trends.
- **Z-score filtering** had minimal effect, especially where early-year data was sparse or inconsistent.
- Analyses proved more robust when restricted to **post-1850 data**, where coverage and consistency improved significantly.
- Due to early data gaps and regional inconsistencies, the dataset is best suited for **global or continental analysis**, rather than granular country-level insights.

> These findings emphasize the importance of pairing robust statistical methods with thoughtful data curation when working with large-scale environmental datasets. The insights presented here can inform both scientific interpretation and strategic planning in climate-related domains.
