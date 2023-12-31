import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../GT_Masters/Printing/CurrencyWordConverter.dart';
import '../GT_Masters/Printing/New_Model_PdfPrint.dart';
import '../GT_Masters/Printing/PDF_2Inch_Print.dart';
import '../appbarWidget.dart';
import '../models/userdata.dart';
import '../urlEnvironment/urlEnvironment.dart';

class Test4 extends StatefulWidget {
  var Parm_Id;
  var Page_Type;
  Test4({this.Parm_Id,this.Page_Type});

  @override
  _Test4State createState() => _Test4State();
}

class _Test4State extends State<Test4> {

  Pdf_Two_Inch Pdf_2=Pdf_Two_Inch();

  late SharedPreferences pref;
  dynamic branch;
  var res;
  dynamic user;
  late int branchId;
  late int userId;
  late UserData userData;
  String branchName = "";
  dynamic userName;
  late String token;
  // var DateTimeFormat = new DateFormat('dd-MM-yyyy hh a');
  var DateTimeFormat = new DateFormat('dd-MM-yyyy');
  String Datetime_Now = DateFormat("yyyy-MM-dd hh:mm:ss").format(DateTime.now());
  var Detailspart;
  var dataForTicket;
  var footerCaptions;
  var  Companydata;
  bool IsArabic=false;
  bool PgA4=true;
  bool Pg_2_Inch=false;
  String IsArabicChkBoxText="Arabic";
  var Pdf_fontSize=9.0;
  var  TaxType;


  var DefaltPage=false;

  // double Pdf_Width=800.0;
  NumberToWord arabicAmount = NumberToWord();
  var currencyName;
  var currencyCoinName;

  void initState() {
    setState(() {
      SharedPreferences.getInstance().then((value) {
        pref = value;
        read();
        GetdataPrint(widget.Parm_Id);
        footerdata();
        GetQrdata();
        GeneralSettings();
        widget.Page_Type==true? PgA4=true:PgA4=false;
        Pagetype(widget.Page_Type);
        dropdownValue=widget.Page_Type;
      });
    });
  }

//------------------for appbar------------
  read() async {
    var v = pref.getString("userData");
    var c = json.decode(v!);
    user = UserData.fromJson(c); // token gets this code user.user["token"]
    setState(() {
      branchId = int.parse(c["BranchId"]);
      token = user.user["token"]; //  passes this user.user["token"]
      pref.setString("customerToken", user.user["token"]);
      branchName = user.branchName;
      userName = user.user["userName"];
      userId = user.user["userId"];
      currencyName = user.user["currencyName"];
      currencyCoinName = user.user["currencyCoinName"];
    });
    var CD=await GetCompantPro(branchId);
  }




  GeneralSettings()async{


    final res =
    await http.get("${Env.baseUrl}generalSettings" as Uri, headers: {
      "Authorization": user.user["token"],
    });

    if(res.statusCode<210) {
      print(res);
      var GenSettingsData = json.decode(res.body);
      print(GenSettingsData[0]["applicationTaxTypeGst"]);
      setState(() {
        GenSettingsData[0]["applicationTaxTypeGst"] ==true ?
        TaxType = "Gst.No" : TaxType = "Vat.No";
        print("TaxType");
        print(TaxType);

      });
    }
  }



  footerdata() async {
    try {
      print("footer data decoded  ");
      final tagsJson =
      await http.get("${Env.baseUrl}SalesInvoiceFooters/" as Uri, headers: {
        "Authorization": user.user["token"],
      });
      var footerdata =await jsonDecode(tagsJson.body);
      setState(() {
        footerCaptions = footerdata;
        // print( "on footerCaptions :" +footerCaptions.toString());
      });

    } catch (e) {
      print(e);
    }
  }

  var Qrdata;
  GetQrdata() async {
    try {
      print("QR datas");
      final tagsJson =
      await http.get("${Env.baseUrl}SalesHeaders/${widget.Parm_Id}/qrcode" as Uri, headers: {
        "Authorization": user.user["token"],
      });
      var footerdata =await jsonDecode(tagsJson.body);
      setState(() {
        Qrdata = footerdata[0]["qrString"];
        print( "QR datas :" +Qrdata.toString());
      });

    } catch (e) {
      print(e);
    }
  }


  GetCompantPro(id)async{
    print("GetCompantPro");
    print(id.toString());
    try {
      final tagsJson =
      await http.get("${Env.baseUrl}MCompanyProfiles/$id" as Uri, headers: {
        //Soheader //SalesHeaders
        "Authorization": user.user["token"],
      });
      if(tagsJson.statusCode==200) {
        Companydata = await jsonDecode(tagsJson.body);
      }
      print( "on GetCompantPro :" +Companydata.toString());
      print(  Companydata['companyProfileAddress1'].toString());
    }
    catch(e){
      print("error on GetCompantPro : $e");
    }
  }


  var  VchDate;
  var  InvTime;
  var TotalTax=0.0;
  var AmountBeforeTax=0.0;
  var TotalQty=0.0;

  GetdataPrint(id) async {
    print("sales for print : $id");
    double amount = 0.0;
    try {
      final tagsJson =
      await http.get("${Env.baseUrl}SalesHeaders/$id" as Uri, headers: {
        //Soheader //SalesHeaders
        "Authorization": user.user["token"],
      });


      dataForTicket = await jsonDecode(tagsJson.body);

      // var ParseDate=dataForTicket['salesHeader'][0]["voucherDate"]??"2022-01-01T00:00:00";
      var ParseDate=dataForTicket['salesHeader'][0]["entryDate"]??"2022-01-01T00:00:00";
      // DateTime tempDate = new DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(ParseDate);
      DateTime tempDate = new DateFormat("yyyy-MM-dd").parse(ParseDate);
      print(dataForTicket['salesHeader'][0]["voucherDate"]);
      VchDate=DateTimeFormat.format(tempDate);
      print(VchDate.toString());


      var  tempTime=dataForTicket['salesHeader'][0]["entryDate"]??"2022-01-01T00:00:00";
      DateTime tempTimeFormate = new DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(tempTime);
      InvTime= DateFormat.jm().format(tempTimeFormate);
      // print("tempTime");
      // print(tempTime);
      // print("tempTimeFormate");
      // print(tempTimeFormate);
      // print("InvTime");
      // print(InvTime);


      Detailspart = dataForTicket['salesDetails'];
      var  Pattern=Detailspart[0]['itmName'];


      print(Detailspart[0]['rate'].runtimeType);
      print(Detailspart[0]['taxPercentage'].runtimeType);
      for(int i = 0; i < Detailspart.length; i++)
      {

        double qty=Detailspart[i]['qty']==null?0.0:(Detailspart[i]['qty']);
        double rate=Detailspart[i]['rate']==null?0.0:(Detailspart[i]['rate']);
        double varTxPer=Detailspart[i]['taxPercentage']==null?0.0:(Detailspart[i]['taxPercentage']);
        double itemTaxrate=Detailspart[i]['taxAmount']??0.0;
        //  double itemTaxrate=await CalculateTaxAmt(rate,qty,varTxPer);
        TotalTax=TotalTax+itemTaxrate;
        TotalQty=TotalQty+qty;
        AmountBeforeTax=AmountBeforeTax+Detailspart[i]['amountBeforeTax'];
      }
      print("TotalTax");
      print(TotalTax.toString());
      // if (Pattern.contains(RegExp(r'[a-zA-Z]'))) {
      //   print("rtertre");
      //
      // }else{
      //   print("Nope, Other characters detected");
      //   IsArabic=true;
      // }

      GetArabicAmount(dataForTicket['salesHeader'][0]["amount"]);

      setState(() {
        IsArabic=false;
      });
    } catch (e) {
      print('error on databinding $e');
    }
  }

  //String dropdownValue = '3 Inch';
  String dropdownValue = 'A4';


  var  AmtInWrds="";
  GetArabicAmount(Amount){
    AmtInWrds= arabicAmount.NumberInRiyals(Amount,currencyName,currencyCoinName);

  }



  //
  // CalculateTaxAmt(double rate,double qty,double taxper){
  //
  //   double  _rate=rate??0.0;
  //   double  _qty=qty??0.0;
  //   double  _taxper=taxper??0.0;
  //
  //
  //   double Tax=((_rate/100)*_taxper);
  //   double  TotTax=(Tax*_qty);
  //   return TotTax;
  // }
  ///---------------------------------------------

  @override
  Widget build(BuildContext context) {
    var ScreenSize=MediaQuery.of(context).size.width;
    var ScreenHeight=MediaQuery.of(context).size.height;

    return
      SafeArea(
        child: Scaffold(
          appBar: PreferredSize(preferredSize: Size.fromHeight(80),
            child: Appbarcustomwidget(uname: userName, branch:branchName, pref: pref, title:"Print"),),

          body: dataForTicket == null ? SizedBox(height: ScreenSize,width: ScreenSize,
              child: Center(child: Text("Loading..."))) :
          Companydata == null ? SizedBox(height: ScreenSize,width: ScreenSize,
              child: Center(child: Text("Loading..."))) :


          PdfPreview(
            initialPageFormat:PdfPageFormat.a4 ,
            allowPrinting: true,
            allowSharing: false,
            canChangePageFormat: false,
            useActions: true,
            build: (format) =>Pg_2_Inch==true? Pdf_2.generatePdf(format, ScreenSize, context, IsArabic, dataForTicket, Companydata, branchName, widget.Parm_Id, footerCaptions, Detailspart):
           PgA4==true?_generatePdfA4(format, ScreenSize,context): _generatePdf3Inch(format, ScreenSize,context),
          ),


          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: InkWell(
                    onTap: (){
                      setState(() {
                        IsArabic = !IsArabic;
                        IsArabic==false?IsArabicChkBoxText="Arabic":IsArabicChkBoxText="English";
                        TableGenerator();
                      });
                    },

                    child: Container(height: 30,width: 100,
                        child: Align(alignment: Alignment.bottomLeft,
                            child: Text(IsArabicChkBoxText,style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),)))),
              ),



              Container(height: 30,
                child:  DropdownButton(
                  underline:Container(color: Colors.transparent),
                  icon:Center(child: Text("$dropdownValue  ▼",style: TextStyle(color: Colors.white),)),

                  items:[

                    DropdownMenuItem<String>(
                      value: "Tax Invoice",
                      child: Text(
                        "Tax Invoice",
                      ),
                    ),

                    DropdownMenuItem<String>(
                      value: "Simplified Invoice",
                      child: Text(
                        "Simplified Invoice",
                      ),
                    ),


                    DropdownMenuItem<String>(
                      value: "A4",
                      child: Text(
                        "A4",
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: "3 Inch",
                      child: Text(
                        "3 Inch",
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: "2 Inch",
                      child: Text(
                        "2 Inch",
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                      Pagetype(dropdownValue);
                      if(dropdownValue== "2 Inch"){
                        Pg_2_Inch=true;
                      }
                    });
                  },

                ),
              ),


            ],
          ),

        ),);
  }




  Future<Uint8List> _generatePdfA4(PdfPageFormat format,
      ScreenSize,BuildContext context) async {
    final pdf = pw.Document(compress: true);
    final font = await rootBundle.load("assets/arial.ttf");
    final ttf = pw.Font.ttf(font);


    pdf.addPage(
      pw.MultiPage(
        textDirection:pw.TextDirection.rtl,
        margin:pw.EdgeInsets.only(top: 20,left: 10,bottom: 20,right: 10),
        //  pageFormat:PgA4==true? PdfPageFormat.a4:PdfPageFormat(80 * PdfPageFormat.mm,double.infinity, marginAll: 5 * PdfPageFormat.mm),
        pageFormat:PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget
          >[ dataForTicket == null ? pw.Text('') :


pw.Column(children: [


  pw.Text(Companydata['companyProfileName']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf,
          fontWeight: pw.FontWeight.bold
      )),

  pw.Text(Companydata['companyProfileNameLatin']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf,
          fontWeight: pw.FontWeight.bold
      )),

  pw.Text(Companydata['companyProfileAddress1']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf)),

  pw.Text(Companydata['companyProfileAddress2']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf)),

  pw.Text(Companydata['companyProfileAddress3']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf)),


  pw.Text(Companydata['companyProfileEmail']??"", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          font: ttf
      )),
  pw.SizedBox(height: 5),
  pw.Text('TAX INVOICE', textAlign: pw.TextAlign.center,
      //textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
          fontSize: Pdf_fontSize,
          // font: ttf,
          decoration:pw.TextDecoration.underline)),

  pw.SizedBox(height: 5),

  pw.Text("فاتورة ضريبية", textAlign: pw.TextAlign.center,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(
        fontSize: Pdf_fontSize,
        font: ttf, )),
  pw.Center(child:pw.SizedBox(child: pw.Divider(),width: ScreenSize/9),heightFactor: 0),
  pw.SizedBox(height: 5),



]),




                  pw.SizedBox(
                    height: 2,),










                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [


                        IsArabic==true ?pw.Padding(padding:pw.EdgeInsets.only(bottom: 5),
                            child: pw.BarcodeWidget(
                              // data: widget.Parm_Id.toString(),
                                data: Qrdata.toString(),
                                barcode: pw.Barcode.qrCode(),
                                width: 50,
                                height: 50
                            )):
                        pw.Text(""),

                        IsArabic==false?pw.Text(""):pw.Spacer(),

                        pw.Container(
                          //color: PdfColors.black,
                          width:ScreenSize,
                          child:            pw.Column(
                              crossAxisAlignment:IsArabic==true ?pw.CrossAxisAlignment.end:pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [

                                ///-----------
                                IsArabic==true?  pw.Text("رقم الفاتورة    ${dataForTicket['salesHeader'][0]["voucherNo"].toString()}  :     ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):


                                pw.Text('Invoice No   : ' +dataForTicket['salesHeader'][0]["voucherNo"].toString(),
                                    // textAlign: pw.TextAlign.left,
                                    // textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),



                                ///-----------
                                // IsArabic==true? pw.Text("رقم الأمر${(dataForTicket['salesHeader'][0]["orderNo"].toString())=="null"?"         - "
                                //     :"           "+ dataForTicket['salesHeader'][0]["orderNo"].toString()} :       ",
                                //     textDirection: pw.TextDirection.rtl,
                                //     style: pw.TextStyle(font: ttf)):
                                //
                                // pw.Text(dataForTicket['salesHeader'][0]["orderNo"]==null?
                                // "  Order No     : -":
                                // '  Order No     : ' +
                                //     dataForTicket['salesHeader'][0]["orderNo"].toString()),


                                ///-----------
                                IsArabic==true? pw.Text("تاريخ${(VchDate.toString())=="null"?"       - "
                                    :"                 "+ VchDate.toString()} :            ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):

                                pw.Text(VchDate==null?
                                "Inv.Date      : -":
                                'Inv.Date      : ' + VchDate.toString(),
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),





                                ///-----------
                                IsArabic==true? pw.Text("زمن${(InvTime.toString())=="null"?"       - "
                                    :"                 "+ InvTime.toString()} :             ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):

                                pw.Text(InvTime==null?
                                "Time            : -":
                                'Time            : ' + InvTime.toString(),
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),
                                //
                                //
                                //
                                //
                                //
                                //
                                // IsArabic==true? pw.Text("تاريخ الطباعة ${(VchDate.toString())=="null"?"       - "
                                //     :"                 "+ VchDate.toString()} :  ",
                                //     textDirection: pw.TextDirection.rtl,
                                //     style: pw.TextStyle(font: ttf)):
                                //
                                // pw.Text(VchDate==null?
                                // "  Print Date   : -":
                                // '  Print Date   : ' + VchDate.toString(),
                                //     style: pw.TextStyle(font: ttf)),




                                ///-----------
                                IsArabic==true?pw.Text('توصيل   ${"    ${dataForTicket['salesHeader'][0]["lhContactNo"]??""}     "+dataForTicket['salesHeader'][0]["partyName"]} :     ',
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf)):
                                pw.Text('Customer    : ${dataForTicket['salesHeader'][0]["partyName"]}  ${dataForTicket['salesHeader'][0]["lhContactNo"]??""}',
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),





                                ///----------------------------

                                dataForTicket['salesHeader'][0]["lhGstno"]!=null?
                                IsArabic==true? pw.Text("ظريبه الشراء ${dataForTicket['salesHeader'][0]["lhGstno"].toString()=="null"?"":dataForTicket['salesHeader'][0]["lhGstno"].toString()} :  ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize,)):

                                pw.Text(
                                    TaxType+"         :${dataForTicket['salesHeader'][0]["lhGstno"].toString()=="null"?"":dataForTicket['salesHeader'][0]["lhGstno"].toString()}",style: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize,)):
                                pw.Text("")





                              ]),
                        ),











                        IsArabic==false?pw.Spacer():pw.Text(""),

                        IsArabic==false ?pw.Padding(padding:pw.EdgeInsets.only(bottom: 5),
                            child: pw.BarcodeWidget(
                              // data: widget.Parm_Id.toString(),
                                data: Qrdata.toString(),
                                barcode: pw.Barcode.qrCode(),
                                width: 50,
                                height: 50
                            )):
                        pw.Text("")

                      ]),








                  // pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  //     children: [
                  //
                  //       pw.Container(
                  //           width: ScreenSize+(ScreenSize/8),
                  //           //color:  PdfColors.red,
                  //           child:  pw.Directionality(
                  //               textDirection:IsArabic==true? pw.TextDirection.rtl: pw.TextDirection.ltr,
                  //               child:
              pw.Partition(child:
                                pw.Table.fromTextArray(
                                    tableWidth:pw.TableWidth.max ,
                                    // border:pw.TableBorder(
                                    //   top: pw.BorderSide(
                                    //       color: PdfColors.black),
                                    //
                                    //   bottom: pw.BorderSide(
                                    //       color: PdfColors.black),),



                                    cellAlignment: pw.Alignment.topRight,
                                    cellAlignments:IsArabic==true? {1: pw.Alignment.topRight,7:pw.Alignment.topRight}: {1: pw.Alignment.topLeft,},
                                    columnWidths:IsArabic==true?
                                    {7: pw.FixedColumnWidth(150),1:pw.FixedColumnWidth(60),0:pw.FixedColumnWidth(50),8:pw.FixedColumnWidth(20),}:
                                    {0:pw.FixedColumnWidth(130),},

                                    cellStyle: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize),
                                    headerStyle: pw.TextStyle(fontWeight:pw.FontWeight.bold,font: ttf,fontSize: 11,),
                                    headerAlignment:pw.Alignment.topRight,
                                    headerAlignments:IsArabic==true? {1: pw.Alignment.topRight,7:pw.Alignment.topRight}: {1: pw.Alignment.topLeft},
                                    headerDecoration: pw.BoxDecoration(border: pw
                                        .Border(bottom: pw.BorderSide(
                                        color: PdfColors.black))),

                                    cellPadding:pw.EdgeInsets.all(1),


                                    headers:TblHeader,
                                    data: TableGenerator()
                                ),
            ),
                        //     )
                        // ),


                      // ]),





                  //pw.SizedBox( height: 2,),

                  //  pw.Container(width:PgA4==true? ScreenSize/1.07:ScreenSize/1.5,
                  pw.Container(
                      //color:  PdfColors.red,
                      child:
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [

                            IsArabic==true?pw.Expanded(child:
                            pw.Align(alignment: pw.Alignment.topLeft,
                              child:pw.Flex(crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  direction: pw.Axis.vertical,
                                  children: [
                                    pw.Text("  :   $TotalQty الكمية الإجمالية",style: pw.TextStyle(fontSize: Pdf_fontSize,font: ttf),
                                      textDirection: pw.TextDirection.rtl,),

                                    pw.Text("$AmtInWrds ",style: pw.TextStyle(fontSize: Pdf_fontSize,font: ttf),
                                      textDirection: pw.TextDirection.rtl,),

                                  ]),),






                            ):
                            pw.Expanded(child:
                            pw.Text("Total Quantity  :  $TotalQty \n $AmtInWrds",style: pw.TextStyle(fontSize: Pdf_fontSize),textAlign: pw.TextAlign.right)),


                      pw.Spacer(),








                            IsArabic==false?pw.Column(

                                children: [
                                  pw.SizedBox(height: 5),
                                  pw.Text("Total Amount Exc Vat  :  ",style: pw.TextStyle(fontSize: 10,font: ttf),  textDirection: pw.TextDirection.rtl,),
                                  pw.Text("Vat Amount                 :  ",style: pw.TextStyle(fontSize: 10,font: ttf) , textDirection: pw.TextDirection.rtl,),
                                  pw.Text("Net Amount     :  ", style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold,font: ttf),  textDirection: pw.TextDirection.rtl,)
                                ]):

                            pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.start,
                                children: [
                                  pw.SizedBox(height: 5),


                                  pw.Text("${AmountBeforeTax.toStringAsFixed(2)} : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),
                                  // pw.Text("${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),


                                  pw.Text("${TotalTax==null?0.0.toStringAsFixed(2):
                                  TotalTax.toStringAsFixed(2)}  : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl),



                                  pw.Text("${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} : ", style: pw.TextStyle(font: ttf,fontSize: 15,fontWeight: pw.FontWeight.bold),textDirection: pw.TextDirection.rtl),
                                ]),









                            IsArabic==false? pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5),

                                  pw.Text("${AmountBeforeTax.toStringAsFixed(2)} ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),

                                  // pw.Text("${dataForTicket['salesHeader'][0]["taxAmt"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["taxAmt"].toStringAsFixed(2)}",style: pw.TextStyle(fontSize: 15,font: ttf),textDirection: pw.TextDirection.rtl),
                                  pw.Text("${TotalTax==null?0.toStringAsFixed(2):
                                  TotalTax.toStringAsFixed(2)} ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl),

                                  // pw.Text("${dataForTicket['salesHeader'][0]["discountAmt"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["discountAmt"].toStringAsFixed(2)}",style: pw.TextStyle(fontSize: 15,font: ttf),textDirection: pw.TextDirection.rtl),

                                  pw.Text(" ${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} ", style: pw.TextStyle(fontSize: 10,fontWeight: pw.FontWeight.bold),textDirection: pw.TextDirection.rtl),
                                ]):

                            pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5),
                                  pw.Text("إجمالي الفاتورة مع",style: pw.TextStyle(fontSize: 10,font: ttf),  textDirection: pw.TextDirection.rtl,),
                                  pw.Text("إجمالي الضرائب",style: pw.TextStyle(fontSize: 10,font: ttf) , textDirection: pw.TextDirection.rtl,),
                                  pw.Text("اجمالى المبيعات", style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold,font: ttf),  textDirection: pw.TextDirection.rtl,)
                                ]),




                          ])

                  ),



            pw.Divider(thickness: 1),



                  pw.SizedBox( height: 2,),



                  //
                  // pw.Row(
                  //     crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  //     children:[
                  //       pw.SizedBox(
                  //         height: 2,),
                  //
                  //
                  //       pw.SizedBox(
                  //         width: 20,),
                  //       pw.SizedBox(height: 2),
                  //
                  //
                  //       // pw.SizedBox(height: 50,width: 100,child:
                  //       // pw.BarcodeWidget(
                  //       //     data: widget.Parm_Id.toString(),
                  //       //     barcode: pw.Barcode.code39(),
                  //       //     width: 100,
                  //       //     height: 50
                  //       // ),
                  //       // )
                  //
                  //     ]),

                  pw.SizedBox(height: 2),
                pw.Center(child: pw.Text(footerCaptions[0]['footerText']+"...",style: pw.TextStyle(fontWeight: pw.FontWeight.bold,font: ttf,fontSize: Pdf_fontSize))
                )
                ];

        },
      ),
    );

    return pdf.save();
  }









  Future<Uint8List> _generatePdf3Inch(PdfPageFormat format,
      ScreenSize,BuildContext context) async {
    final pdf = pw.Document(compress: true);
    final font = await rootBundle.load("assets/arial.ttf");
    final ttf = pw.Font.ttf(font);

    // var Total;
    // var Vat;
    // var Discount;
    // var Net_Amount;
    //
    // if(IsArabic==true){
    //   Total="Total";
    //   Vat="Vat";
    //   Discount="Discount";
    //   Net_Amount="Net Amount";
    // }else{
    //
    //   Total="مجموع";
    //   Vat="ضريبة";
    //   Discount="خصم";
    //   Net_Amount="كمية الشبكة";
    // }


    pdf.addPage(
      pw.Page(
        margin:pw.EdgeInsets.only(top: 2,left: 2,bottom: 2,right: 2),
        pageFormat:PdfPageFormat.roll80,
        build: (context) {
          return  pw.FittedBox(fit: pw.BoxFit.fill,
              child: dataForTicket == null ? pw.Text('') : pw.ListView(
                children: [


                  pw.Text(Companydata['companyProfileName']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf,
                          fontWeight: pw.FontWeight.bold
                      )),

                  pw.Text(Companydata['companyProfileNameLatin']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf,
                          fontWeight: pw.FontWeight.bold
                      )),

                  pw.Text(Companydata['companyProfileAddress1']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf)),

                  pw.Text(Companydata['companyProfileAddress2']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf)),

                  pw.Text(Companydata['companyProfileAddress3']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf)),


                  pw.Text(Companydata['companyProfileEmail']??"", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          font: ttf
                      )),
                  pw.SizedBox(height: 5),
                  pw.Text('TAX INVOICE', textAlign: pw.TextAlign.center,
                      //textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          fontSize: Pdf_fontSize,
                          // font: ttf,
                          decoration:pw.TextDecoration.underline)),

                  pw.SizedBox(height: 5),

                  pw.Text("فاتورة ضريبية", textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        fontSize: Pdf_fontSize,
                        font: ttf, )),
                  pw.Center(child:pw.SizedBox(child: pw.Divider(),width: ScreenSize/9),heightFactor: 0),
                  pw.SizedBox(height: 5),





                  pw.SizedBox(
                    height: 2,),










                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [


                        IsArabic==true ?pw.Padding(padding:pw.EdgeInsets.only(bottom: 5),
                            child: pw.BarcodeWidget(
                              // data: widget.Parm_Id.toString(),
                                data: Qrdata.toString(),
                                barcode: pw.Barcode.qrCode(),
                                width: 50,
                                height: 50
                            )):
                        pw.Text(""),


                        pw.Container(
                          //color: PdfColors.black,
                          width:ScreenSize,
                          child:            pw.Column(
                              crossAxisAlignment:IsArabic==true ?pw.CrossAxisAlignment.end:pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [

                                ///-----------
                                IsArabic==true?  pw.Text("رقم الفاتورة    ${dataForTicket['salesHeader'][0]["voucherNo"].toString()}  :     ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):


                                pw.Text('Invoice No   : ' +dataForTicket['salesHeader'][0]["voucherNo"].toString(),
                                    // textAlign: pw.TextAlign.left,
                                    // textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),



                                ///-----------
                                // IsArabic==true? pw.Text("رقم الأمر${(dataForTicket['salesHeader'][0]["orderNo"].toString())=="null"?"         - "
                                //     :"           "+ dataForTicket['salesHeader'][0]["orderNo"].toString()} :       ",
                                //     textDirection: pw.TextDirection.rtl,
                                //     style: pw.TextStyle(font: ttf)):
                                //
                                // pw.Text(dataForTicket['salesHeader'][0]["orderNo"]==null?
                                // "  Order No     : -":
                                // '  Order No     : ' +
                                //     dataForTicket['salesHeader'][0]["orderNo"].toString()),


                                ///-----------
                                IsArabic==true? pw.Text("تاريخ${(VchDate.toString())=="null"?"       - "
                                    :"                 "+ VchDate.toString()} :            ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):

                                pw.Text(VchDate==null?
                                "Inv.Date      : -":
                                'Inv.Date      : ' + VchDate.toString(),
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),





                                ///-----------
                                IsArabic==true? pw.Text("زمن${(InvTime.toString())=="null"?"       - "
                                    :"                 "+ InvTime.toString()} :             ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)):

                                pw.Text(InvTime==null?
                                "Time            : -":
                                'Time            : ' + InvTime.toString(),
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),
                                //
                                //
                                //
                                //
                                //
                                //
                                // IsArabic==true? pw.Text("تاريخ الطباعة ${(VchDate.toString())=="null"?"       - "
                                //     :"                 "+ VchDate.toString()} :  ",
                                //     textDirection: pw.TextDirection.rtl,
                                //     style: pw.TextStyle(font: ttf)):
                                //
                                // pw.Text(VchDate==null?
                                // "  Print Date   : -":
                                // '  Print Date   : ' + VchDate.toString(),
                                //     style: pw.TextStyle(font: ttf)),




                                ///-----------
                                IsArabic==true?pw.Text('توصيل   ${"    ${dataForTicket['salesHeader'][0]["lhContactNo"]??""}     "+dataForTicket['salesHeader'][0]["partyName"]} :     ',
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf)):
                                pw.Text('Customer    : ${dataForTicket['salesHeader'][0]["partyName"]}  ${dataForTicket['salesHeader'][0]["lhContactNo"]??""}',
                                    style: pw.TextStyle(font: ttf, fontSize: Pdf_fontSize,)),





                                ///----------------------------

                                dataForTicket['salesHeader'][0]["lhGstno"]!=null?
                                IsArabic==true? pw.Text("ظريبه الشراء ${dataForTicket['salesHeader'][0]["lhGstno"].toString()=="null"?"":dataForTicket['salesHeader'][0]["lhGstno"].toString()} :  ",
                                    textDirection: pw.TextDirection.rtl,
                                    style: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize,)):

                                pw.Text(
                                    TaxType+"         :${dataForTicket['salesHeader'][0]["lhGstno"].toString()=="null"?"":dataForTicket['salesHeader'][0]["lhGstno"].toString()}",style: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize,)):
                                pw.Text("")





                              ]),
                        ),













                        IsArabic==false ?pw.Padding(padding:pw.EdgeInsets.only(bottom: 5),
                            child: pw.BarcodeWidget(
                              // data: widget.Parm_Id.toString(),
                                data: Qrdata.toString(),
                                barcode: pw.Barcode.qrCode(),
                                width: 50,
                                height: 50
                            )):
                        pw.Text("")

                      ]),








                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [

                        pw.Container(
                            width: ScreenSize+(ScreenSize/8),
                            //color:  PdfColors.red,
                            child:  pw.Directionality(
                                textDirection:IsArabic==true? pw.TextDirection.rtl: pw.TextDirection.ltr,
                                child:
                                pw.Table.fromTextArray(
                                    tableWidth:pw.TableWidth.max ,
                                    // border:pw.TableBorder(
                                    //   top: pw.BorderSide(
                                    //       color: PdfColors.black),
                                    //
                                    //   bottom: pw.BorderSide(
                                    //       color: PdfColors.black),),





                                    cellAlignment: pw.Alignment.topRight,

                                    cellAlignments:IsArabic==true?{1: pw.Alignment.topRight,7:pw.Alignment.topRight}:
                                    {1: pw.Alignment.topRight,0: pw.Alignment.topLeft,},

                                    columnWidths:IsArabic==true?
                                    {7: pw.FixedColumnWidth(150),1:pw.FixedColumnWidth(60),0:pw.FixedColumnWidth(50),8:pw.FixedColumnWidth(20),}:
                                    {0:pw.FixedColumnWidth(130),},


                                    cellStyle: pw.TextStyle(font: ttf,fontSize: Pdf_fontSize),

                                    headerStyle: pw.TextStyle(fontWeight:pw.FontWeight.bold,font: ttf,fontSize: 11,),

                                    headerAlignment:pw.Alignment.topRight,

                                    headerAlignments:IsArabic==true? {1: pw.Alignment.topRight,7:pw.Alignment.topRight}:
                                    {1: pw.Alignment.topRight,0: pw.Alignment.topLeft},

                                    headerDecoration: pw.BoxDecoration(border: pw
                                        .Border(bottom: pw.BorderSide(
                                        color: PdfColors.black))),

                                    cellPadding:pw.EdgeInsets.all(1),


                                    headers:TblHeader,
                                    data: TableGenerator()
                                )
                            )
                        ),


                      ]),





                  //pw.SizedBox( height: 2,),

                  //  pw.Container(width:PgA4==true? ScreenSize/1.07:ScreenSize/1.5,
                  pw.Container(width:ScreenSize+(ScreenSize/8),
                      //color:  PdfColors.red,
                      child:
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [

                            IsArabic==true?pw.Expanded(child:
                            pw.Align(alignment: pw.Alignment.topLeft,
                              child:pw.Flex(crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  direction: pw.Axis.vertical,
                                  children: [
                                    pw.Text("  :   $TotalQty الكمية الإجمالية",style: pw.TextStyle(fontSize: Pdf_fontSize,font: ttf),
                                      textDirection: pw.TextDirection.rtl,),

                                    pw.Text("$AmtInWrds ",style: pw.TextStyle(fontSize: Pdf_fontSize,font: ttf),
                                      textDirection: pw.TextDirection.rtl,),

                                  ]),),






                            ):
                            pw.Expanded(child:
                            pw.Text("Total Quantity  :  $TotalQty \n $AmtInWrds",style: pw.TextStyle(fontSize: Pdf_fontSize))),






                            IsArabic==false?pw.Column(
                                children: [
                                  pw.SizedBox(height: 5),
                                  pw.Text("Total Amount Exc Vat  :  ",style: pw.TextStyle(fontSize: 10,font: ttf),  textDirection: pw.TextDirection.rtl,),
                                  pw.Text("Vat Amount                 :  ",style: pw.TextStyle(fontSize: 10,font: ttf) , textDirection: pw.TextDirection.rtl,),
                                  pw.Text("Net Amount     :  ", style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold,font: ttf),  textDirection: pw.TextDirection.rtl,)
                                ]):

                            pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5),


                                  pw.Text("${AmountBeforeTax.toStringAsFixed(2)} : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),
                                  // pw.Text("${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),


                                  pw.Text("${TotalTax==null?0.0.toStringAsFixed(2):
                                  TotalTax.toStringAsFixed(2)} : ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl),



                                  pw.Text("${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} : ", style: pw.TextStyle(font: ttf,fontSize: 15,fontWeight: pw.FontWeight.bold),textDirection: pw.TextDirection.rtl),
                                ]),



                            IsArabic==false? pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5),

                                  pw.Text("${AmountBeforeTax.toStringAsFixed(2)} ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl,),

                                  // pw.Text("${dataForTicket['salesHeader'][0]["taxAmt"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["taxAmt"].toStringAsFixed(2)}",style: pw.TextStyle(fontSize: 15,font: ttf),textDirection: pw.TextDirection.rtl),
                                  pw.Text("${TotalTax==null?0.toStringAsFixed(2):
                                  TotalTax.toStringAsFixed(2)} ",style: pw.TextStyle(fontSize: 10,font: ttf),textDirection: pw.TextDirection.rtl),

                                  // pw.Text("${dataForTicket['salesHeader'][0]["discountAmt"]==null?0.toStringAsFixed(2):
                                  // dataForTicket['salesHeader'][0]["discountAmt"].toStringAsFixed(2)}",style: pw.TextStyle(fontSize: 15,font: ttf),textDirection: pw.TextDirection.rtl),

                                  pw.Text(" ${dataForTicket['salesHeader'][0]["amount"]==null?0.toStringAsFixed(2):
                                  dataForTicket['salesHeader'][0]["amount"].toStringAsFixed(2)} ", style: pw.TextStyle(fontSize: 10,fontWeight: pw.FontWeight.bold),textDirection: pw.TextDirection.rtl),
                                ]):

                            pw.Column(
                                crossAxisAlignment:pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5),
                                  pw.Text("إجمالي الفاتورة مع      ",style: pw.TextStyle(fontSize: 10,font: ttf),  textDirection: pw.TextDirection.rtl,),
                                  pw.Text("إجمالي الضرائب      ",style: pw.TextStyle(fontSize: 10,font: ttf) , textDirection: pw.TextDirection.rtl,),
                                  pw.Text("اجمالى المبيعات   ", style: pw.TextStyle(fontSize: 15,fontWeight: pw.FontWeight.bold,font: ttf),  textDirection: pw.TextDirection.rtl,)
                                ]),


                          ])

                  ),


                  pw.SizedBox(
                    height: 10,width:ScreenSize+(ScreenSize/8),
                    child:pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.SizedBox(height:2 ,child: pw.Divider(),width:ScreenSize+(ScreenSize/8))

                        ]),
                  ),




                  pw.SizedBox( height: 2,),




                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children:[
                        pw.SizedBox(
                          height: 2,),


                        pw.SizedBox(
                          width: 20,),
                        pw.SizedBox(height: 2),


                        // pw.SizedBox(height: 50,width: 100,child:
                        // pw.BarcodeWidget(
                        //     data: widget.Parm_Id.toString(),
                        //     barcode: pw.Barcode.code39(),
                        //     width: 100,
                        //     height: 50
                        // ),
                        // )

                      ]),

                  pw.SizedBox(height: 2),
                  pw.Text(footerCaptions[0]['footerText']+"...",style: pw.TextStyle(fontWeight: pw.FontWeight.bold,font: ttf,fontSize: Pdf_fontSize))

                ],
              ),

          );
        },
      ),
    );

    return pdf.save();
  }


  var TblHeader;
  TableGenerator() {
    if(IsArabic==true){
      PgA4==true?TblHeader= ['Amount\n المجموع', 'TaxAmt\n مبلغ الضريبة', 'Tax%\n  الضريبة٪',"Total\n مجموع", 'Qty\n كمية', 'Price\n  معدل\n','Unit\n وحدة', 'name\tItem\n التفاصيل','No\n عدد']:
      TblHeader= ['Amount  المجموع', 'Tax% الضريبة٪', 'Qty كمية', 'Price معدل', 'Item name التفاصيل\n'];
    }
    else{
      PgA4==true? TblHeader = <dynamic>['No ',' Item Name','Unit ', 'Rate ', 'Qty ','Total ', 'Tax% ', 'Tax Amt ', 'Amount ']
          : TblHeader = <dynamic>['Item Name', 'Rate', 'Qty', 'Tax%', 'Amount'];

    }




    var purchasesAsMap;
    if(IsArabic==true){

      if(PgA4==true) {
        var Slnum=0;
        purchasesAsMap = <Map<String, String>>[
          for(int i = 0; i < Detailspart.length; i++)
            {

              "NetAmt": "${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)} ",
              //"sssf": "${CalculateTaxAmt((Detailspart[i]['rate']),(Detailspart[i]['qty']),(Detailspart[i]['taxPercentage']))} ",
              "TaxAmt": "${Detailspart[i]['taxAmount'].toStringAsFixed(2)=="0.00"?"":Detailspart[i]['taxAmount'].toStringAsFixed(2)} ",
              "TaxPer": "${Detailspart[i]['taxPercentage']==null?"0.00":Detailspart[i]['taxPercentage'].toStringAsFixed(2)} ",
              "total": "${(Detailspart[i]['qty']??0.0)*(Detailspart[i]['rate']??0.0)} ",
              "Qty": "${Detailspart[i]['qty']} ",
              "Rate": "${Detailspart[i]['rate'].toStringAsFixed(2)} ",
              "Unit": "${Detailspart[i]['uom']??""} ",
              "ItemName": "${Detailspart[i]['itmName']??""} ${Detailspart[i]['itmArabicName']??""}",
              "No": "${(++Slnum).toString()} ",

            },
        ];
      }  else{
        purchasesAsMap = <Map<String, String>>[
          for(int i = 0; i < Detailspart.length; i++)
            {
              "ssss":"${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)}",
              "sss":"${Detailspart[i]['taxPercentage']==null?"0.00":Detailspart[i]['taxPercentage'].toStringAsFixed(2)}",
              "ssshhs":"${Detailspart[i]['qty']}",
              "ss":"${Detailspart[i]['rate'].toStringAsFixed(2)}",
              "s":"${Detailspart[i]['itmName']}",
            },
        ];
      }



    }else{

      if(PgA4==true) {
        var Slnum=0;
        purchasesAsMap = <Map<String, String>>[
          for(int i = 0; i < Detailspart.length; i++)
            {
              "No": "${(++Slnum).toString()} ",
              "ItemName": " ${Detailspart[i]['itmName']}",
              "Unit": "${Detailspart[i]['uom']??""} ",
              "Rate": "${Detailspart[i]['rate'].toStringAsFixed(2)} ",
              "Qty": "${Detailspart[i]['qty']} ",
              "total": "${(Detailspart[i]['qty']??0.0)*(Detailspart[i]['rate']??0.0)} ",
              "TaxPer": "${Detailspart[i]['taxPercentage']==null?"0.00":Detailspart[i]['taxPercentage'].toStringAsFixed(2)} ",
              // "sssf": "${CalculateTaxAmt((Detailspart[i]['rate']),(Detailspart[i]['qty']),(Detailspart[i]['taxPercentage']))} ",
              "TaxAmt": "${Detailspart[i]['taxAmount'].toStringAsFixed(2)=="0.00"?"":Detailspart[i]['taxAmount'].toStringAsFixed(2)} ",
              "NetTotal": "${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)} ",
            },
        ];
      }  else{
        purchasesAsMap = <Map<String, String>>[
          for(int i = 0; i < Detailspart.length; i++)
            {
              "s": "${Detailspart[i]['itmName']}",
              "ss": "${Detailspart[i]['rate'].toStringAsFixed(2)}",
              "ssshhs": "${Detailspart[i]['qty']}",
              "sss": "${Detailspart[i]['taxPercentage']==null?"0.00":Detailspart[i]['taxPercentage'].toStringAsFixed(2)}",
              "ssss": " ${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)}",
            },
        ];
      }




    }

    // if(PgA4==true) {
    //   purchasesAsMap = <Map<String, String>>[
    //     for(int i = 0; i < Detailspart.length; i++)
    //       {
    //         "s": "${Detailspart[i]['itmName']}",
    //         "ss": "${Detailspart[i]['rate'].toStringAsFixed(2)}",
    //         "ssshhs": "${Detailspart[i]['qty']}",
    //         "sss": "${Detailspart[i]['taxPercentage']}",
    //         "sssf": "${Detailspart[i]['taxAmount'].toStringAsFixed(2)}",
    //         "ssss": "${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)}",
    //       },
    //   ];
    // }
    // else{
    //   purchasesAsMap = <Map<String, String>>[
    //     for(int i = 0; i < Detailspart.length; i++)
    //       {
    //         "s": "${Detailspart[i]['itmName']}",
    //         "ss": "${Detailspart[i]['rate'].toStringAsFixed(2)}",
    //         "ssshhs": "${Detailspart[i]['qty']}",
    //         "sss": "${Detailspart[i]['taxPercentage']}",
    //         "ssss": "${Detailspart[i]['amountIncludingTax'].toStringAsFixed(2)}",
    //       },
    //   ];
    // }

    List<List<String>> listOfPurchases = [];
    for (int i = 0; i < purchasesAsMap.length; i++) {
      listOfPurchases.add(purchasesAsMap[i].values.toList());
    }
    return listOfPurchases;
  }




  // ['Amount المجموع', 'TaxAmt\n مبلغ الضريبة', 'Tax% الضريبة٪', 'Qty\n كمية', 'Price معدل', 'name\tItem\n التفاصيل']


  Pagetype(pgTyp) {

    if(pgTyp=="Tax Invoice"|| pgTyp=="Simplified Invoice"){

      Navigator.of(context,rootNavigator: true).pop();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  New_Model_PdfPrint(Parm_Id:widget.Parm_Id,Page_Type:pgTyp=="Tax Invoice"?true:false)));


    }else{



      setState(() {
        Pg_2_Inch = false;
        if (IsArabic == true) {
          pgTyp == "A4" ? PgA4 = true : PgA4 = false;
          PgA4 == true ?
          TblHeader = <dynamic>[
            'Amount\n المجموع',
            'TaxAmt\n مبلغ الضريبة',
            'Tax%\n  الضريبة٪',
            'Total\n مجموع',
            'Qty\n كمية',
            'Price\n  معدل\n',
            'Unit\n وحدة',
            'name\tItem\n التفاصيل',
            'No\n عدد'
          ] :
          TblHeader = <dynamic>[
            'Amount المجموع',
            'Tax% الضريبة٪',
            'Qty كمية',
            'Price معدل',
            'Item name التفاصيل'
          ];
          print("PgA4");
          print(PgA4);
        } else {
          pgTyp == "A4" ? PgA4 = true : PgA4 = false;
          PgA4 == true ?
          TblHeader = <dynamic>[
            'No ',
            ' Item Name',
            'Unit ',
            'Rate ',
            'Qty ',
            'Total ' 'Tax% ',
            'Tax Amt ',
            'Amount '
          ]
              : TblHeader =
          <dynamic>['Item Name', 'Rate', 'Qty', 'Tax%', 'Amount'];
          print("PgA4");
          print(PgA4);
        }
      });
    }
  }
}
