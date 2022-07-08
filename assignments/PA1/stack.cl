(*
 *  Stanford CS143
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *)

class List inherits IO {
    item : String;
    next : List;

    item() : String { item };
    next() : List { next };

    init(i: String, n: List) : List {
        {
            item <- i;
            next <- n;
            self;
        }
    };

    insert(val : String) : List {
        (new List).init(val, self)
    };

    evaluate() : List {
        {
            if (item = "+") then
                let val1 : Int <- (new A2I).a2i(next.item()),
                    val2 : Int <- (new A2I).a2i(next.next().item()),
                    newval : String <- (new A2I).i2a(val1 + val2)
                in
                    next.next().next().insert(newval)
            else
                if (item = "s") then
                    let val1 : String <- next.item(),
                        val2 : String <- next.next().item()
                    in
                        next.next().next().insert(val1).insert(val2)
                else self fi
            fi;
        }
    };

    display() : Object {
        if not(item = "bottom") then
            {
                out_string(item.concat("\n"));
                next.display();
            }
        else
            ""
        fi
    };
};

class Main inherits IO {
    main() : Object {
        {
            out_string(">");
            let ch : String <- in_string(),
                nil : List,
                head : List <- (new List).init("bottom", nil),
                item1 : String,
                item2 : String,
                newitem : String
            in
            {
                while (not (ch = "x")) loop
                    {
                        if (ch = "d") then head.display() else
                        {
                            if (ch = "s") then head <- head.insert("s") else
                            {
                                if (ch = "+") then head <- head.insert("+") else
                                {
                                    if (ch = "e") then
                                        head <- head.evaluate()
                                    else
                                        head <- head.insert(ch)
                                    fi;
                                }
                                fi;
                            }
                            fi;
                        }
                        fi;
                        out_string(">");
                        ch <- in_string();
                    }
                pool;
            };
        }
    };
};