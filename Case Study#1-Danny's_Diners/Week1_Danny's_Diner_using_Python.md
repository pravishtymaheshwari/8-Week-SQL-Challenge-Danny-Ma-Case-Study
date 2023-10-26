
# Connection setup with SQL Database.
```python
import pandas as pd
import sqlalchemy as sal
import numpy as np

Engine = sal.create_engine('mssql://HP\SQLEXPRESS/dannys_diner?driver=ODBC+Driver+17+for+SQL+Server')
Conn = Engine.connect()
```

# Importing tables from SSMS.
```python
df_sales = pd.read_sql_query('select * from sales',Conn)
df_members = pd.read_sql_query('select * from members',Conn)
df_menu = pd.read_sql_query('select * from menu',Conn)
```


# Case Study Questions

**1. What is the total amount each customer spent at the restaurant?**
```python
df_merged = df_sales.merge(df_menu, on='product_id',how='inner')
df_merged = df_merged.groupby('customer_id')['price'].sum().reset_index(name='total_amount_spent')
df_merged['total_amount_spent'] = '$' + df_merged['total_amount_spent'].astype('str')
df_merged
```




<div>

<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>total_amount_spent</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>$76</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>$74</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>$36</td>
    </tr>
  </tbody>
</table>
</div>



**2. How many days has each customer visited the restaurant?**
```python
df_sales.groupby('customer_id')['order_date'].nunique().reset_index()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>order_date</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>4</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>6</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>2</td>
    </tr>
  </tbody>
</table>
</div>



**3. What was the first item from the menu purchased by each customer?**
```python
df_merged = df_sales.merge(df_menu,on='product_id')
df_merged = df_merged.drop_duplicates(keep='first')
df_merged['rnk'] = df_merged.groupby('customer_id')['order_date'].rank(method = 'dense', ascending=True)
df_merged[df_merged['rnk']==1].groupby('customer_id')['product_name'].apply(lambda x: ','.join(x)).reset_index()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>product_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>sushi,curry</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>curry</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>ramen</td>
    </tr>
  </tbody>
</table>
</div>



**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```python
df_merged = df_sales.merge(df_menu, on='product_id')
df_merged = df_merged.groupby('product_name')['product_name'].count().reset_index(name='total_purchases')
df_merged[df_merged['total_purchases'] == df_merged['total_purchases'].max()]
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>product_name</th>
      <th>total_purchases</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>1</th>
      <td>ramen</td>
      <td>8</td>
    </tr>
  </tbody>
</table>
</div>



**5. Which item was the most popular for each customer?**
```python
df_merged = df_sales.merge(df_menu, on='product_id')
df_merged = df_merged.groupby(['customer_id','product_name'])['product_name'].count().reset_index(name='cnt')
df_merged['rnk'] = df_merged.groupby('customer_id')['cnt'].rank(method='dense',ascending=False)
df_merged = df_merged[df_merged['rnk']==df_merged['rnk'].min()][['customer_id','product_name']]
df_merged.groupby('customer_id')['product_name'].apply(lambda x: ','.join(x)).reset_index()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>product_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>ramen</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>curry,ramen,sushi</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>ramen</td>
    </tr>
  </tbody>
</table>
</div>



**6. Which item was purchased first by the customer after they became a member?**

```python
df_merged = df_sales.merge(df_members,on='customer_id')
df_merged = df_merged.merge(df_menu,on='product_id')
df_merged['rnk'] = df_merged[df_merged['order_date']>=df_merged['join_date']].groupby('customer_id')['order_date'].rank(method='dense',ascending=True)
df_merged[df_merged['rnk']==1][['customer_id','product_name']].sort_values(by='customer_id')
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>product_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>4</th>
      <td>A</td>
      <td>curry</td>
    </tr>
    <tr>
      <th>2</th>
      <td>B</td>
      <td>sushi</td>
    </tr>
  </tbody>
</table>
</div>



**7. Which item was purchased just before the customer became a member?**

```python
df_merged = df_sales.merge(df_members,on='customer_id')
df_merged = df_merged.merge(df_menu,on='product_id')
df_merged['rnk'] = df_merged[df_merged['order_date']<df_merged['join_date']].groupby('customer_id')['order_date'].rank(method='dense',ascending=False)
df_merged[df_merged['rnk']==1].groupby('customer_id')['product_name'].apply(lambda x: ','.join(x)).reset_index()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>product_name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>sushi,curry</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>sushi</td>
    </tr>
  </tbody>
</table>
</div>



**8. What is the total items and amount spent for each member before they became a member?**

```python
df_merged = df_sales.merge(df_members,how = 'left',on='customer_id')
df_merged = df_merged.merge(df_menu, on='product_id')
df_merged = df_merged[(df_merged['order_date']<df_merged['join_date']) | (df_merged['join_date'].isna())].groupby('customer_id')['price'].sum().reset_index(name='total_amount_spent')
df_merged['total_amount_spent'] = '$'+ df_merged['total_amount_spent'].astype('str')
df_merged
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>total_amount_spent</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>$25</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>$40</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>$36</td>
    </tr>
  </tbody>
</table>
</div>



**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

```python
df_merged = df_sales.merge(df_members,how = 'left',on='customer_id')
df_merged = df_merged.merge(df_menu, on='product_id')
df_merged['price'] = np.where(df_merged['product_name'].str.lower()=='sushi',2*10*df_merged['price'],10*df_merged['price'])
df_merged.groupby('customer_id')['price'].sum().reset_index(name='total_points')
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>total_points</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>860</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>940</td>
    </tr>
    <tr>
      <th>2</th>
      <td>C</td>
      <td>360</td>
    </tr>
  </tbody>
</table>
</div>



**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just
sushi - how many points do customer A and B have at the end of January?**
```python
df_merged = df_merged = df_sales.merge(df_members,on='customer_id')
df_merged = df_merged.merge(df_menu, on='product_id')
df_merged['price'] = np.where(df_merged['product_name'].str.lower()=='sushi',2*10*df_merged['price'],
                              np.where((df_merged['order_date']>=df_merged['join_date']) & (df_merged['order_date']<= df_merged['join_date']+ pd.Timedelta(days=6)), 2*10*df_merged['price'],10*df_merged['price']))
df_merged[pd.to_datetime(df_merged['order_date'])<= pd.to_datetime('2021-01-31')].groupby('customer_id')['price'].sum().reset_index()
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>price</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>1370</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>820</td>
    </tr>
  </tbody>
</table>
</div>



**Bonus Questions: Recreate the following table output using the available data:**



```python
df_merged = df_merged = df_sales.merge(df_members,how='left',on='customer_id')
df_merged = df_merged.merge(df_menu, on='product_id')
df_merged['member'] = np.where(df_merged['order_date']>=df_merged['join_date'],'Y','N')
df_merged.sort_values(['customer_id','order_date','product_name'])
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>order_date</th>
      <th>product_id</th>
      <th>join_date</th>
      <th>product_name</th>
      <th>price</th>
      <th>member</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>3</th>
      <td>A</td>
      <td>2021-01-01</td>
      <td>2</td>
      <td>2021-01-07</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
    </tr>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>2021-01-01</td>
      <td>1</td>
      <td>2021-01-07</td>
      <td>sushi</td>
      <td>10</td>
      <td>N</td>
    </tr>
    <tr>
      <th>4</th>
      <td>A</td>
      <td>2021-01-07</td>
      <td>2</td>
      <td>2021-01-07</td>
      <td>curry</td>
      <td>15</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>7</th>
      <td>A</td>
      <td>2021-01-10</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>8</th>
      <td>A</td>
      <td>2021-01-11</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>9</th>
      <td>A</td>
      <td>2021-01-11</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>5</th>
      <td>B</td>
      <td>2021-01-01</td>
      <td>2</td>
      <td>2021-01-09</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
    </tr>
    <tr>
      <th>6</th>
      <td>B</td>
      <td>2021-01-02</td>
      <td>2</td>
      <td>2021-01-09</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>2021-01-04</td>
      <td>1</td>
      <td>2021-01-09</td>
      <td>sushi</td>
      <td>10</td>
      <td>N</td>
    </tr>
    <tr>
      <th>2</th>
      <td>B</td>
      <td>2021-01-11</td>
      <td>1</td>
      <td>2021-01-09</td>
      <td>sushi</td>
      <td>10</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>10</th>
      <td>B</td>
      <td>2021-01-16</td>
      <td>3</td>
      <td>2021-01-09</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>11</th>
      <td>B</td>
      <td>2021-02-01</td>
      <td>3</td>
      <td>2021-01-09</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>12</th>
      <td>C</td>
      <td>2021-01-01</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
    </tr>
    <tr>
      <th>13</th>
      <td>C</td>
      <td>2021-01-01</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
    </tr>
    <tr>
      <th>14</th>
      <td>C</td>
      <td>2021-01-07</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
    </tr>
  </tbody>
</table>
</div>



**Rank All The Things: Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.**

```python
df_merged = df_merged = df_sales.merge(df_members,how='left',on='customer_id')
df_merged = df_merged.merge(df_menu, on='product_id')
df_merged['member'] = np.where(df_merged['order_date']>=df_merged['join_date'],'Y','N')
df_merged['ranking'] = np.where(df_merged['member']=='N', np.nan, df_merged.groupby(['customer_id','member'])['order_date'].rank(method='dense',ascending=True))
df_merged.sort_values(['customer_id','order_date'])
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>customer_id</th>
      <th>order_date</th>
      <th>product_id</th>
      <th>join_date</th>
      <th>product_name</th>
      <th>price</th>
      <th>member</th>
      <th>ranking</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>A</td>
      <td>2021-01-01</td>
      <td>1</td>
      <td>2021-01-07</td>
      <td>sushi</td>
      <td>10</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>3</th>
      <td>A</td>
      <td>2021-01-01</td>
      <td>2</td>
      <td>2021-01-07</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>4</th>
      <td>A</td>
      <td>2021-01-07</td>
      <td>2</td>
      <td>2021-01-07</td>
      <td>curry</td>
      <td>15</td>
      <td>Y</td>
      <td>1.0</td>
    </tr>
    <tr>
      <th>7</th>
      <td>A</td>
      <td>2021-01-10</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>8</th>
      <td>A</td>
      <td>2021-01-11</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
      <td>3.0</td>
    </tr>
    <tr>
      <th>9</th>
      <td>A</td>
      <td>2021-01-11</td>
      <td>3</td>
      <td>2021-01-07</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
      <td>3.0</td>
    </tr>
    <tr>
      <th>5</th>
      <td>B</td>
      <td>2021-01-01</td>
      <td>2</td>
      <td>2021-01-09</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>6</th>
      <td>B</td>
      <td>2021-01-02</td>
      <td>2</td>
      <td>2021-01-09</td>
      <td>curry</td>
      <td>15</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>1</th>
      <td>B</td>
      <td>2021-01-04</td>
      <td>1</td>
      <td>2021-01-09</td>
      <td>sushi</td>
      <td>10</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>2</th>
      <td>B</td>
      <td>2021-01-11</td>
      <td>1</td>
      <td>2021-01-09</td>
      <td>sushi</td>
      <td>10</td>
      <td>Y</td>
      <td>1.0</td>
    </tr>
    <tr>
      <th>10</th>
      <td>B</td>
      <td>2021-01-16</td>
      <td>3</td>
      <td>2021-01-09</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
      <td>2.0</td>
    </tr>
    <tr>
      <th>11</th>
      <td>B</td>
      <td>2021-02-01</td>
      <td>3</td>
      <td>2021-01-09</td>
      <td>ramen</td>
      <td>12</td>
      <td>Y</td>
      <td>3.0</td>
    </tr>
    <tr>
      <th>12</th>
      <td>C</td>
      <td>2021-01-01</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>13</th>
      <td>C</td>
      <td>2021-01-01</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
    <tr>
      <th>14</th>
      <td>C</td>
      <td>2021-01-07</td>
      <td>3</td>
      <td>NaN</td>
      <td>ramen</td>
      <td>12</td>
      <td>N</td>
      <td>NaN</td>
    </tr>
  </tbody>
</table>
</div>




```python

```
