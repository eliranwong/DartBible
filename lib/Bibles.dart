import 'Helpers.dart';
import 'BibleParser.dart';

class Bibles {

  var bible1, bible2;

  Map getBibles() => {1: this.bible1, 2: this.bible1};

  Future getALLBibleList() async {
    var fileIO = FileIOHelper();
    var bibleFolder = fileIO.getDataPath("bible");
    var bibleList = await fileIO.getFileListInFolder(bibleFolder);
    bibleList = bibleList.where((i) => (i.endsWith(".json") as bool)).toList();
    bibleList = bibleList.map((i) => fileIO.getBasename(i.substring(0, (i.length - 5)))).toList();
    bibleList.sort();
    return bibleList;
  }

  Future getValidBibleList(List bibleList) async {
    var validBibleList = [];
    var allBibleList = await this.getALLBibleList();
    for (var bible in bibleList) {
      if (allBibleList.contains(bible)) validBibleList.add(bible);
    }
    validBibleList.sort();
    return validBibleList;
  }

  Future loadBible(String bibleModule, [int bibleID = 1]) async {
    var allBibleList = await this.getALLBibleList();
    if (!(allBibleList.contains(bibleModule))) {
      return false;
    } else {
      switch (bibleID) {
        case 1:
          if ((this.bible1 == null) || ((this.bible1 != null) && (this.bible1.module != bibleModule))) {
            this.bible1 = Bible(bibleModule);
            //print("Bible 1 loaded");
          }
          break;
        case 2:
          if ((this.bible2 == null) || ((this.bible2 != null) && (this.bible2.module != bibleModule))) {
            this.bible2 = Bible(bibleModule);
            //print("Bible 2 loaded");
          }
          break;
      }
      return true;
    }
  }

  Future openBible(String bibleModule, String referenceString, [int bibleID = 1]) async {
    if (referenceString.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleModule, bibleID);
      if (bibleIsLoaded) {
        var referenceList = BibleParser().extractAllReferences(referenceString);
        if (referenceList.isNotEmpty) this.getBibles()[bibleID].open(referenceList);
      }
    }
  }

  Future searchBible(String bibleModule, String searchString, [int bibleID = 1]) async {
    if (searchString.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleModule, bibleID);
      if (bibleIsLoaded) this.getBibles()[bibleID].search(searchString);
    }
  }

  Future compareBibles(String bibleString, String referenceString, [int bibleID = 1]) async {
    var bibleList;
    (bibleString == "ALL") ? bibleList = await this.getALLBibleList() : bibleList = await this.getValidBibleList(bibleString.split("_"));
    if (bibleList.isNotEmpty) {
      var referenceList = BibleParser().extractAllReferences(referenceString);
      if (referenceList.isNotEmpty) this.compareVerses(referenceList, bibleList);  
    }
  }

  Future compareVerses(List listOfBcvList, List bibleList) async {
    String versesFound = "";

    for (var bcvList in listOfBcvList) {
      versesFound += "[Compare ${BibleParser().bcvToVerseReference(bcvList)}]\n";
      for (var bible in bibleList) {
        var verseText = await Bible(bible).openSingleVerse(bcvList);
        versesFound += "[$bible] $verseText\n";
      }
      versesFound += "\n";
    }
    print(versesFound);
  }

  Future parallelBibles(String bibleString, String referenceString, [int bibleID = 1]) async {
    String versesFound = "";

    var bibleList = await this.getValidBibleList(bibleString.split("_"));
    if (bibleList.length >= 2) {
      var bible1IsLoaded = await this.loadBible(bibleList[0], 1);
      if (bible1IsLoaded) {
        var bible2IsLoaded = await this.loadBible(bibleList[1], 2);
        if (bible2IsLoaded) {
          var referenceList = BibleParser().extractAllReferences(referenceString);
          if (referenceList.length >= 1) {
            var bcvList = referenceList[0];
            versesFound += "[${BibleParser().bcvToChapterReference(bcvList)}]\n";

            var b = bcvList[0];
            var c = bcvList[1];
            var v = bcvList[2];

            var bible1VerseList = await this.bible1.getVerseList(b, c);
            var vs1 = bible1VerseList[0];
            var ve1 = bible1VerseList[(bible1VerseList.length - 1)];

            var bible2VerseList = await this.bible2.getVerseList(b, c);
            var vs2 = bible2VerseList[0];
            var ve2 = bible2VerseList[(bible2VerseList.length - 1)];

            var vs, ve;
            (vs1 <= vs2) ? vs = vs1 : vs = vs2;
            (ve1 >= ve2) ? ve = ve1 : ve = ve2;

            for (var i = vs; i <= ve; i++) {
              var verseText1 = await this.bible1.openSingleVerse([b, c, i]);
              var verseText2 = await this.bible2.openSingleVerse([b, c, i]);
              if (i == v) {
                versesFound += "**********\n[$i] [${this.bible1.module}] $verseText1\n";
                versesFound += "[$i] [${this.bible2.module}] $verseText2\n**********";    
              } else {
                versesFound += "\n[$i] [${this.bible1.module}] $verseText1\n";
                versesFound += "[$i] [${this.bible2.module}] $verseText2\n";
              }
            }
          }
        }
      }
    }
    print(versesFound);
  }

  Future crossReference(String bibleString, String referenceString, [int bibleID = 1]) async {
    var referenceList = BibleParser().extractAllReferences(referenceString);

    var xRefList;
    if (referenceList.isNotEmpty) xRefList = await this.getCrossReference(referenceList[0]);
    if (xRefList.isNotEmpty) {
      var bibleIsLoaded = await this.loadBible(bibleString, 1);
      if (bibleIsLoaded) this.bible1.openMultipleVerses(xRefList);
    }
  }

  Future getCrossReference(List bcvList) async {
    var filePath = FileIOHelper().getDataPath("xRef", "xRef");
    var jsonObject = await JsonHelper().getJsonObject(filePath);
    var bcvString = bcvList.join(".");
    var fetchResults = jsonObject.where((i) => (i["bcv"] == bcvString)).toList();
    var referenceString = fetchResults[0]["xref"];
    return BibleParser().extractAllReferences(referenceString);
  }

  Future parallelVerses(List bcvList) async {
    print("pending");
  }

  Future parallelChapters(List bcvList) async {
    print("pending");
  }

}

class Bible {

  var biblePath;
  var module;
  var data;

  Bible(String bible) {
    this.biblePath = FileIOHelper().getDataPath("bible", bible);
    this.module = bible;
  }

  Future loadData() async {
    this.data = await JsonHelper().getJsonObject(this.biblePath);
  }

  Future open(List referenceList) async {
    if (this.data == null) await this.loadData();

    ((referenceList.length == 1) && (referenceList[0].length == 3)) ? this.openSingleChapter(referenceList[0]) : this.openMultipleVerses(referenceList);
  }

  Future getBookList() async {
    if (this.data == null) await this.loadData();

    Set books = {};
    for (var i in this.data) {
      books.add(i["bNo"]);
    }
    var bookList = books.toList();
    bookList.sort();
    return bookList;
  }

  Future getChapterList(int b) async {
    if (this.data == null) await this.loadData();

    Set chapters = {};
    var fetchResults = this.data.where((i) => (i["bNo"] == b)).toList();
    for (var i in fetchResults) {
      chapters.add(i["cNo"]);
    }
    var chapterList = chapters.toList();
    chapterList.sort();
    return chapterList;
  }

  Future getVerseList(int b, int c) async {
    if (this.data == null) await this.loadData();

    Set verses = {};
    var fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c))).toList();
    for (var i in fetchResults) {
      verses.add(i["vNo"]);
    }
    return verses.toList();
    var verseList = verses.toList();
    verseList.sort();
    return verseList;
  }

  Future openSingleVerse(List bcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";

    var b = bcvList[0];
    var c = bcvList[1];
    var v = bcvList[2];

    var fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == v))).toList();
    for (var found in fetchResults) {
      var verseText = found["vText"].trim();
      versesFound += "$verseText";
    }

    return versesFound.trimRight();
  }

  Future openSingleVerseRange(List bcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";

    var b = bcvList[0];
    var c = bcvList[1];
    var v = bcvList[2];
    var c2 = bcvList[3];
    var v2 = bcvList[4];

    var check, fetchResults;

    if ((c2 == c) && (v2 > v)) {
      check = v;
      while (check <= v2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = "[${found["vNo"]}] ${found["vText"].trim()}";
          versesFound += "$verseText ";
        }
        check += 1;
      }
    } else if (c2 > c) {
      check = c;
      while (check < c2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = found["vText"].trim();
          versesFound += "$verseText ";
        }
        check += 1;
      }
      check = 0; // some bible versions may have chapters starting with verse 0.
      while (check <= v2) {
        fetchResults = this.data.where((i) => ((i["bNo"] == b) && (i["cNo"] == c) && (i["vNo"] == check))).toList();
        for (var found in fetchResults) {
          var verseText = found["vText"].trim();
          versesFound += "$verseText ";
        }
        check += 1;
      }
    }

    return versesFound.trimRight();
  }

  Future openSingleChapter(List bcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "[${BibleParser().bcvToChapterReference(bcvList)}]\n";
    var fetchResults = this.data.where((i) => ((i["bNo"] == bcvList[0]) && (i["cNo"] == bcvList[1]))).toList();
    for (var found in fetchResults) {
      var b = found["bNo"];
      var c = found["cNo"];
      var v = found["vNo"];
      var verseText = found["vText"].trim();
      (v == bcvList[2]) ? versesFound += "**********\n[$v] $verseText\n**********\n" : versesFound += "[$v] $verseText\n";
    }
    print(versesFound);
  }

  Future openMultipleVerses(List listOfBcvList) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";
    for (var bcvList in listOfBcvList) {
      versesFound += "[${BibleParser().bcvToVerseReference(bcvList)}] ";
      if (bcvList.length == 5) {
        var verse = await openSingleVerseRange(bcvList);
        versesFound += "$verse\n\n";
      } else {
        var verse = await openSingleVerse(bcvList);
        versesFound += "$verse\n\n";
      }
    }
    print(versesFound);
  }

  Future search(String searchString) async {
    if (this.data == null) await this.loadData();

    String versesFound = "";
    var fetchResults = this.data.where((i) => (i["vText"].contains(RegExp(searchString)) as bool)).toList();
    for (var found in fetchResults) {
      var b = found["bNo"];
      var c = found["cNo"];
      var v = found["vNo"];
      var bcvRef = BibleParser().bcvToVerseReference([b, c, v]);
      var verseText = found["vText"];
      versesFound += "[$bcvRef] $verseText\n\n";
    }
    print(versesFound);
    print("$searchString is found in ${fetchResults.length} verse(s).\n");
  }

}