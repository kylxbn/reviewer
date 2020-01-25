use "ui.eh"
use "list.eh"
use "form.eh"
use "dataio.eh"
use "dict.eh"
use "rnd.eh"
use "dialog.eh"
use "string.eh"

const APP_VERSION = "1.4"
const APP_DATE = "July 1, 2013"
const APP_TIME = "11:44PM"

def wait_menu(): String {
    var e: UIEvent
    var c = true
    while (c) {
        e = ui_wait_event()
        if (e.kind == EV_MENU) c = false }
    e.value.cast(Menu).text }

def credits() {
    var c = new Form()
    c.title = "Credits & greetings"
    c.add_menu(new Menu("Okay", 0, MT_CANCEL))
    c.add(new TextItem("Idea, programming and design:", "Kyle Alexander Buan <tar.shoduze@gmail.com>"))
    c.add(new TextItem("Compiled by:", "Nokia N95 8GB"))
    c.add(new TextItem("Compiler:", "Alchemy OS nec version 2.1"))
    c.add(new TextItem("Build date & time:", APP_DATE + ", " + APP_TIME))
    ui_set_screen(c)
    wait_menu() }

def all_is_not_answered(l: [Byte], c: Byte): Bool {
    var r = true
    for (var i=0, i<l.len, i+=1) if (l[i] < c) r = false
    !r }

def compare(user: [EditItem], given: List): Bool {
    var user_array = new [String](user.len)
    var user_correct = new [Bool](user.len)
    for (var i=0, i<user.len, i+=1) user_array[i] = user[i].text
    for (var i=0, i<user.len, i+=1) user_correct[i] = false
    for (var i=0, i<user.len, i+=1) {
        for (var j=0, j<user.len, j+=1) {
            if (user_array[i].lcase() == given[j].cast(String).lcase()) user_correct[i] = true } }
    var res = true
    for (var i=0, i<user.len, i+=1)
        if (user_correct[i] == false) res = false
    res }

def ask_question(index: Int, q: List, a: Dict, c: [Byte]): Byte {
    var d=new Form()
    d.title = "Question"
    d.add(new TextItem("Question #" + (index+1).tostr()+ " (correctly answered "+c[index].tostr()+" times)", q[index].cast(String)))
    var ans = new [EditItem](a[index].cast(List).len())
    for (var i=0, i<a[index].cast(List).len(), i+=1) {
        ans[i] = new EditItem((i+1).tostr(), "", EDIT_ANY, 100)
        d.add(ans[i]) }
    d.add_menu(new Menu("Answer", 0))
    d.add_menu(new Menu("Skip", 1, MT_CANCEL))
    d.add_menu(new Menu("Cancel review", 2))
    ui_set_screen(d)
    var r = wait_menu()
    var score = 0
    if (r=="Answer") {
        if (compare(ans, a[index].cast(List))) {
            c[index] += 1 }
        else {
            var e = new Form()
            e.title = "Answer"
            d.add(new TextItem(q[index].cast(String), ""))
            for (var i=0, i<a[index].cast(List).len(), i+=1)
                e.add(new TextItem((i+1).tostr(), a[index].cast(List)[i].cast(String)))
            e.add_menu(new Menu("Okay", 0))
            ui_set_screen(e)
            r = wait_menu() } }
    else if (r == "Cancel review") score = 1
    score }

def go_review(data: List) {
    var repeatf = new Form()
    repeatf.title = "Repetition"
    var repeat = new EditItem("How many times should each question be answered correctly?", "2", EDIT_NUMBER, 2)
    repeatf.add(repeat)
    repeatf.add_menu(new Menu("Okay", 0))
    ui_set_screen(repeatf)
    wait_menu()
    var answerdict = new Dict()
    var questionlist = new List()
    var temp = 0
    var j = 0
    var qcount = 0
    for (var i=0, i<data.len(), i+=1) {
        temp = data[i].cast(Int) // num of q
        questionlist.add(data[i+1].cast(String)) // q
        answerdict.set(qcount, new List())
        for (j=0, j<temp, j+=1) {
            answerdict.get(qcount).cast(List).add(data[i+2+j].cast(String)) } // a
        i += 1+temp
        qcount += 1 }
    var correctlist = new [Byte](questionlist.len())
    for (var i =0, i<correctlist.len, i+=1) correctlist[i] = 0
    var random = 0
    var sc = 0
    do {
        do {
            random = rnd(correctlist.len) }
        while (correctlist[random] > repeat.text.toint() - 1)
        sc = ask_question(random, questionlist, answerdict, correctlist) }
    while (all_is_not_answered(correctlist, repeat.text.toint()) && (sc != 1))
    if (sc == 1) {
        var ab= ""
        var fin = new Form()
        fin.title = "Review cancelled"
        fin.add_menu(new Menu("Okay", 0, MT_CANCEL))
        var totalcorrect = 0
        for (var i=0, i<correctlist.len, i+=1) {
            if (correctlist[i] > 0) totalcorrect += 1 }
        fin.add(new TextItem("You correctly answered", totalcorrect.tostr()+" out of "+correctlist.len.tostr()+" unique questions!"))
        fin.add(new TextItem("", "Here are the answers to the questions you didn't correctly answer:"))
        for (var i=0, i<correctlist.len, i+=1) {
            if (correctlist[i] == 0) {
                ab = ""
                for (j=0, j<answerdict[i].cast(List).len(), j+=1)
                    ab += answerdict[i].cast(List)[j].cast(String) + "\n"
                fin.add(new TextItem(questionlist[i].cast(String), ab)) } }
        ui_set_screen(fin)
        wait_menu() }
    else {
        var fin = new Form()
        fin.title = "Review finished"
        fin.add_menu(new Menu("Okay", 0, MT_CANCEL))
        fin.add(new TextItem("Congratulations!", "You successfully answered all the questions. I wish you luck on your studies! Remember to study with me again next time :)"))
        ui_set_screen(fin)
        wait_menu() } }

def load_data(path: String): List {
    var data = new List()
    var in = fopen_r(path)
    var c = true
    var temp = in.readubyte()
    var i = 0
    do {
        data.add(temp)
        data.add(in.readutf())
        for (i=0, i<temp, i+=1) {
            data.add(in.readutf()) }
        try {
            temp = in.readubyte() }
        catch {
            c = false } }
    while (c)
    data }

def review() {
    var path = run_filechooser("Choose reviewer", "/res/reviewer/reviewers", ["*"])
    if (path != null) {
        var data = load_data(path)
        go_review(data) } }

def n_question(n: Form, data: List) {
    var q = new Form()
    var anscount = 1
    q.title = "Add question"
    q.add(new EditItem("Question:", "", EDIT_ANY, 200))
    q.add(new EditItem("Answer(s):", "", EDIT_ANY, 100))
    q.add_menu(new Menu("Done", 0))
    q.add_menu(new Menu("More answers", 1))
    q.add_menu(new Menu("Less answers", 2))
    q.add_menu(new Menu("Cancel", 3, MT_CANCEL))
    ui_set_screen(q)
    var r = ""
    var c = true
    do {
        r = wait_menu()
        if (r=="Done") {
            var a=""
            data.add(q.size() - 1)
            data.add(q.get(0).cast(EditItem).text)
            for (var i=1, i<q.size(), i+=1) {
                a += q.get(i).cast(EditItem).text + "\n"
                data.add(q.get(i).cast(EditItem).text) }
            n.add(new TextItem(q.get(0).cast(EditItem).text, a))
            c = false }
        if (r=="More answers") {
            q.add(new EditItem(anscount.tostr(), "", EDIT_ANY, 100))
            anscount += 1 }
        if (r=="Less answers") q.remove(q.size()-1)
        if (r=="Cancel") c = false }
    while (c) }

def save(data: List) {
    var s = new Form()
    s.title = "Save"
    var n = new EditItem("Reviewer name:", "New", EDIT_ANY, 64)
    s.add(n)
    s.add_menu(new Menu("Done", 0))
    s.add_menu(new Menu("Cancel", 1, MT_CANCEL))
    ui_set_screen(s)
    var r = wait_menu()
    var temp: Int = 0
    var j=0
    if (r=="Done") {
        if (!(exists("/res/reviewer") && is_dir("/res/reviewer"))) mkdir("/res/reviewer")
        if (!(exists("/res/reviewer/reviewers") && is_dir("/res/reviewer/reviewers"))) mkdir("/res/reviewer/reviewers")
        var out = fopen_w("/res/reviewer/reviewers/"+n.text)
        for (var i=0, i<data.len(), i+=1) {
            temp = data[i].cast(Int)
            out.writebyte(temp)
            out.writeutf(data[i+1].cast(String))
            for (j=0, j<temp, j+=1) {
                out.writeutf(data[i+2+j].cast(String)) }
            i += 1+temp }
        out.close() } }

def rm_reviewer() {
    var p = run_filechooser("Delete reviewer", "/res/reviewer/reviewers", ["*"])
    if (p != null) fremove(p) }

def e_reviewer() {
    var p: String = null
    do {
        p = run_filechooser("Edit reviewer", "/res/reviewer/reviewers", ["*"])
        if (p==null) run_msgbox("Error", "Please choose a reviewer first, then you may cancel while editing.", ["Okay"]) }
    while (p == null)
    var data = load_data(p)
    var n = new Form()
    n.title = "New reviewer"
    n.add_menu(new Menu("Add question...", 0))
    n.add_menu(new Menu("Remove last question", 1))
    n.add_menu(new Menu("Save...", 2))
    n.add_menu(new Menu("Cancel", 3))
    ui_set_screen(n)
    var c = true
    var r = ""
    var temp = 0
    var add_q = ""
    var add_a = ""
    for (var i=0, i<data.len(), i+=1) {
        add_a = ""
        temp = data[i].cast(Int)
        add_q = data[i+1].cast(String)
        for (var j=0, j<temp, j+=1) {
            add_a += data[i+2+j].cast(String) + "\n" }
        i += 1 + temp
        n.add(new TextItem(add_q, add_a)) }
    var rem_count = 0
    var last_rem_count = 0
    do {
        r = wait_menu()
        if (r == "Add question...") {
            n_question(n, data)
            ui_set_screen(n) }
        if (r == "Remove last question") {
            n.remove(n.size()-1)
            while (rem_count < data.len()) {
                last_rem_count = rem_count
                rem_count += data[rem_count].cast(Byte) + 2 }
            while (last_rem_count < data.len()) data.remove(data.len()-1) }
        if (r == "Save...") {
            save(data)
            ui_set_screen(n) }
        if (r == "Cancel") c = false }
    while (c) }

def n_reviewer() {
    var n = new Form()
    n.title = "New reviewer"
    n.add_menu(new Menu("Add question...", 0))
    n.add_menu(new Menu("Remove last question", 1))
    n.add_menu(new Menu("Save...", 2))
    n.add_menu(new Menu("Cancel", 3))
    ui_set_screen(n)
    var c = true
    var r = ""
    var data = new List()
    var rem_count = 0
    var last_rem_count = 0
    do {
        r = wait_menu()
        if (r == "Add question...") {
            n_question(n, data)
            ui_set_screen(n) }
        if (r == "Remove last question") {
            n.remove(n.size()-1)
            while (rem_count < data.len()) {
                last_rem_count = rem_count
                rem_count += data[rem_count].cast(Byte) + 2 }
            while (last_rem_count < data.len()) data.remove(data.len()-1) }
        if (r == "Save...") {
            save(data)
            ui_set_screen(n) }
        if (r == "Cancel") c = false }
    while (c) }

def main(args: [String]) {
    var main_menu = new Form()
    main_menu.title = "REVIEWER"
    var greetings: [String] = ["You look fine today. What did you do?", "Hello!", "At your service!", "Let's review!", "I love learning!", "Hey, don't be angry. Relax :)", "I'm here to help you review!", "What's up?", "If you feel tired of reviewing, I advice you to stop. Only review when you feel excited to review, or else you will not remember anything after reviewing.", "Studying can be very hard sometimes. Rest, but never give up! I know you can do it!", "Hi, nice to meet you! Can I interview you about what you learned at school? :)"]
    main_menu.add(new TextItem("REVIEWER " + APP_VERSION, greetings[rnd(greetings.len)]))
    main_menu.add_menu(new Menu("Review...", 0))
    main_menu.add_menu(new Menu("New reviewer...", 1))
    main_menu.add_menu(new Menu("Edit reviewer...", 2))
    main_menu.add_menu(new Menu("Delete reviewer...", 3))
    main_menu.add_menu(new Menu("Credits & greetings...", 4))
    main_menu.add_menu(new Menu("Exit Reviewer", 5, MT_CANCEL))
    ui_set_screen(main_menu)
    var c = true
    var r = ""
    do {
        r = wait_menu()
        if (r == "Review...") {
            review()
            ui_set_screen(main_menu) }
        else if (r == "New reviewer...") {
            n_reviewer()
            main_menu[0] = new TextItem("REVIEWER " + APP_VERSION, greetings[rnd(greetings.len)])
            ui_set_screen(main_menu) }
        else if (r == "Delete reviewer...") {
            rm_reviewer()
            main_menu[0] = new TextItem("REVIEWER " + APP_VERSION, greetings[rnd(greetings.len)])
            ui_set_screen(main_menu) }
        else if (r == "Edit reviewer...") {
            e_reviewer()
            main_menu[0] = new TextItem("REVIEWER " + APP_VERSION, greetings[rnd(greetings.len)])
            ui_set_screen(main_menu) }
        else if (r == "Credits & greetings...") {
            credits()
            main_menu[0] = new TextItem("REVIEWER " + APP_VERSION, greetings[rnd(greetings.len)])
            ui_set_screen(main_menu) }
        else if (r == "Exit Reviewer") {
            c = false
            run_alert("Exiting", "Goodbye :)", null, 1000) } }
    while (c) }
