#!/usr/bin/env python

import pandas
import tkinter as tk
from tkinter import Tk
from tkinter import filedialog
from tkinter import messagebox
import os
import csv
import sys
import numpy

# open product sales csv
sales_files = Tk()

sales_files.withdraw()
sales_files.fileName = filedialog.askopenfilename(filetypes = (("csv files", "*.csv"),("All files", "*.*")))
sales_df = pandas.read_csv(sales_files.fileName)
sales_df.columns = sales_df.columns.str.strip().str.lower().str.replace(' ', '_').str.replace('(', '').str.replace(')', '')

# open folder with merchant prices
merchant_files = Tk()
merchant_files.withdraw()
merchant_files.fileName = filedialog.askdirectory()
merchant_file_list = os.listdir(merchant_files.fileName)

exempt_file = Tk()
exempt_file.withdraw()
exempt_file.fileName = filedialog.askopenfilename(filetypes = (("csv files", "*.csv"),("All files", "*.*")))
exempt_file_list = list(pandas.read_csv(exempt_file.fileName).merchant_name)
######################################
revenue_dic = {}
saved_location = {}
cost_variation_dic = {}
error_products_dic = {}
itemized_dic = {}
list_merchants = []
list_order_id = []

sales_df["category_name"] = sales_df["category_name"].astype(str).replace('nan',numpy.nan)
sales_df["product_name"] = sales_df["product_name"].astype(str).replace('nan',numpy.nan)
sales_df["distance_in_km"] = pandas.to_numeric(sales_df["distance_in_km"])
sales_df["quantity"] = pandas.to_numeric(sales_df["quantity"])
sales_df["delivery_address"] = sales_df["delivery_address"].astype(str)

for i in sales_df.index:
    salesrow = sales_df.loc[sales_df.index == i]
    merchant = salesrow.store_name.iloc[0]
    product_name = salesrow.product_name.iloc[0]
    category_name = salesrow.category_name.iloc[0]
    unit_price = salesrow.unit_price.iloc[0]
    customization_option = salesrow.customization_option.iloc[0]
    quantity = salesrow.quantity.iloc[0]
    tip = salesrow.tip.iloc[0]
    order_id = salesrow.order_id.iloc[0]
    
    if salesrow.delivery_address.iloc[0] == "Mobile Food Truck" or salesrow.distance_in_km.iloc[0] == 0:
        is_pickup = True
        pickup_delivery = "Pickup"
    else:
        is_pickup = False
        pickup_delivery = "Delivery"
    
    if merchant is None:
        messagebox.showerror("Error", "Store name variable empty for product name: " + i)
        sys.exit(0)
    else:
        pass

    merchantx = merchant.replace("'", "_")
    merchantx = merchantx.replace("|", "_")

    if quantity is None:
        messagebox.showerror("Error", "Quantity variable empty for product name: " + i)
        sys.exit(0)
    else:
        pass

    merchant_file_name = merchantx + ".csv"
    if merchant_file_name in merchant_file_list:
        merchant_df = pandas.read_csv(merchant_files.fileName + "/" + merchantx + ".csv")
    elif merchant_file_name in saved_location:
        merchant_df = pandas.read_csv(saved_location[merchant_file_name])
    else:
        # disambiguation
        messagebox.showerror("Disambiguation", merchantx + " is not found in your markups folder. Hit OK and select which file to use.")
        merchant_file_name_choice = Tk()
        merchant_file_name_choice.withdraw()
        merchant_file_name_choice.fileName = filedialog.askopenfilename(filetypes = (("csv files", "*.csv"),("All files", "*.*")))
        saved_location[merchant_file_name] = merchant_file_name_choice.fileName
        merchant_df = pandas.read_csv(merchant_file_name_choice.fileName)

    if merchant_df is None:
        messagebox.showerror("Error", "Did not find a .csv file with the name " + merchantx + " .csv in the folder specified")
        sys.exit(0)
    else:
        pass

    merchant_df.columns = merchant_df.iloc[0]
    merchant_df = merchant_df.drop(merchant_df.index[0])
    merchant_df = merchant_df.reset_index(drop = True)
    merchant_df["Product Name"] = merchant_df["Product Name"].astype(str).replace('nan',numpy.nan)
    # merchant_df["Cost Variation"] = pd.to_numeric(merchant_df["Cost Variation"])
    
    try:
        merchant_df["Original Price"] = pandas.to_numeric(merchant_df["Original Price"])
    except:
        messagebox.showerror("Error", "Could not convert Original Price column from" + merchantx + " .csv to numeric. Skipping. Needs debug.")
        continue

    try:
        pricerow = merchant_df.loc[(merchant_df['Product Name'] == product_name) & (merchant_df['Category Name'] == category_name)]
    except:
        if pandas.isnull(product_name) is False:
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + product_name
                continue
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + product_name}
                continue
        else:
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + customization_option
                continue
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + customization_option}
                continue

    if pandas.isnull(product_name) is False:
        pricerow = merchant_df.loc[(merchant_df['Product Name'] == product_name) & (merchant_df['Category Name'] == category_name)]
    elif unit_price == "-":
        continue
    else:
        pricerow = merchant_df.loc[(merchant_df['Product Name'] == customization_option) & (merchant_df['Category (Internal)'] == "Add - On")]

    try:
        price = pricerow["Original Price"].iloc[0]
    except:
        if pandas.isnull(product_name) is False:
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + product_name
                continue              
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + product_name}
                continue
        else: 
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + customization_option
                continue              
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + customization_option}
                continue
            
        # messagebox.showerror("Error", "Some products were skipped due to errors. Check the list in the summary csv for products that may not be correctly listed in their merchant csvs.)
        
    else:
        price = pricerow["Original Price"].iloc[0]

    if pandas.isnull(price) is False:
       pass
    else:
        if pandas.isnull(product_name) is False:
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + product_name
                continue              
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + product_name}
                continue
        else: 
            if merchant in error_products_dic:
                error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + customization_option
                continue              
            else:
                error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + customization_option}
                continue

    if isinstance(price, (float, int, numpy.float64, numpy.int64)):
       pass
    else:
        messagebox.showerror("Error. Index", str(i + 2) + " from " + merchant + " has a price that is either empty or not an float. It will be skipped and recorded")
        if merchant in error_products_dic:
            error_products_dic[merchant]["Index: " + str(i + 2)] = merchant + ": " + product_name
            continue              
        else:
            error_products_dic[merchant] = {"Index: " + str(i + 2):merchant + ": " + product_name}
            continue

    total = price * quantity
    
    if is_pickup is False:
        tip = 0
        if merchant not in exempt_file_list:
            if pricerow["Category Name"].iloc[0] != "Donate":
                total = total * 0.909
            else:
                merchant = merchant + " Donation"
        else:
            pass
    else:
        if order_id in list_order_id:
            tip = 0
            pass
        elif tip == "-":
            tip = 0
            list_order_id.append(order_id)
        else:
            tip = float(tip)
            list_order_id.append(order_id)

        if pricerow["Category Name"].iloc[0] != "Donate":
            pass
        else:
            merchant = merchant + " Donation"
    
    if merchant in revenue_dic:
        revenue_dic[merchant] = revenue_dic[merchant] + total + tip
    else:
        revenue_dic[merchant] = total + tip

    merchant = salesrow.store_name.iloc[0]
    
    if merchant in list_merchants:
        pass
    else:
        list_merchants.append(merchant)

    if pandas.isnull(product_name) is False:
        if merchant in itemized_dic:
            if product_name in itemized_dic[merchant]:
                if pickup_delivery in itemized_dic[merchant][product_name]:
                    itemized_dic[merchant][product_name][pickup_delivery] = [itemized_dic[merchant][product_name][pickup_delivery][0] + total, itemized_dic[merchant][product_name][pickup_delivery][1] + quantity]
                else:
                    itemized_dic[merchant][product_name][pickup_delivery] = [total, quantity]
            else:
                itemized_dic[merchant][product_name] = {pickup_delivery:[total, quantity]}
        else:
            itemized_dic[merchant] = {product_name:{pickup_delivery:[total, quantity]}}
    else:
        customization_option = "Customization: " + customization_option
        if merchant in itemized_dic:
            if customization_option in itemized_dic[merchant]:
                if pickup_delivery in itemized_dic[merchant][customization_option]:
                    itemized_dic[merchant][customization_option][pickup_delivery] = [itemized_dic[merchant][customization_option][pickup_delivery][0] + total, itemized_dic[merchant][customization_option][pickup_delivery][1] + quantity]
                else:
                    itemized_dic[merchant][customization_option][pickup_delivery] = [total, quantity]
            else:
                itemized_dic[merchant][customization_option] = {pickup_delivery:[total, quantity]}
        else:
            itemized_dic[merchant] = {customization_option:{pickup_delivery:[total, quantity]}}

    if tip != 0:
        itemized_dic[merchant]["Order " + str(order_id) + ": Customer Tip"] = {pickup_delivery:[tip, 1]}
    else:
        pass

save_folder = Tk()
save_folder.withdraw()
save_folder.fileName = filedialog.askdirectory(title = "Choose Save Folder")

with open(save_folder.fileName + '/General_Summary.csv', 'w', newline="") as csv_file:  
    writer = csv.writer(csv_file)

    writer.writerow(["Merchant Name", "Payout"])
    for key, value in revenue_dic.items():
       writer.writerow([key, value])
    
    writer.writerow("")
    writer.writerow(["Index Not Found (or other error) Excluded", "Store Name and Product Name"])
    for key2, error in error_products_dic.items():
        for store, value2 in error_products_dic[key2].items():
            writer.writerow([store, value2])

for j in list_merchants:
    with open(save_folder.fileName + '/' + j + '_Itemized.csv', 'w', newline="") as csv_file:  
        writer = csv.writer(csv_file)

        writer.writerow(["Merchant Name", "Payout"])
        writer.writerow([j , revenue_dic[j]])
        if j + " Donation" in revenue_dic.keys():
            writer.writerow([j + "Donation", revenue_dic[j + " Donation"]])
        else:
            pass
        
        # store name: product name, pickup/delivery, payout, quantity
        writer.writerow("")
        writer.writerow(["Itemized Payouts"])

        writer.writerow("")
        writer.writerow(["Product Name", "Pickup/Delivery", "Payout", "Quantity"])
        temp_dic = itemized_dic[j]
        for product, value3 in temp_dic.items():
            for pd, value4 in temp_dic[product].items():
                writer.writerow([product, pd, value4[0], value4[1]])

        try:
            temp_dic = error_products_dic[j]
        except:
            continue

        writer.writerow("")
        writer.writerow(["Index Not Found (or other error) Excluded", "Product Name"])

        for key2, error2 in temp_dic.items():
            writer.writerow([key2, error2])
