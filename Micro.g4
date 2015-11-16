grammar Micro;

@header{
    import java.util.Arrays;
}

COMMENT : '--' ~[\n]* -> skip ;
KEYWORD : 'PROGRAM' | 'BEGIN' | 'END' | 'FUNCTION' | 'READ' | 'WRITE' | 'IF' | 'ELSE' | 'FI' | 'FOR' | 'ROF' | 'CONTINUE' | 'BREAK' | 'RETURN' | 'INT' | 'VOID' | 'STRING' | 'FLOAT';
IDENTIFIER : [a-zA-Z][a-zA-Z0-9]*;
INTLITERAL : ('0'..'9')+;
OPERATOR : (':=' | '+' | '-' | '*' | '/' | '=' | '!=' | '<' | '>' | '(' | ')' | ';' | ',' | '<=' | '>=');
WHITESPACE : [ \t\n\r]+ -> skip;
STRINGLITERAL : '"'~["]*'"';
FLOATLITERAL : ('0'..'9')+.('0'..'9')+;


/*--------------------*/


/* Program */
program : 'PROGRAM' id 'BEGIN' pgm_body 'END';
id : IDENTIFIER;
pgm_body locals [int label_num = 1, int var_num = 1, ArrayList<String> glob_vars = new ArrayList<String>();, ArrayList<String> true_globals = new ArrayList<String>();] : DECL=decl FUNC=func_declarations {
    ArrayList<String> vars = new ArrayList<String>();

    for (String var : $DECL.res) {
        String[] split = var.split(" ");
        if (split[3].charAt(0) == 'S') {
            String var_string = "S " + split[1] + " ";
            var_string += var.substring(var.indexOf("\""));
            vars.add("str " + split[1] + " " + var.substring(var.indexOf("\"")));
            $true_globals.add("S " + var);
        } else {
            $glob_vars.add(split[3].charAt(0) + " " + split[1]);
            $true_globals.add(split[3].charAt(0) + " " + split[1]);
            vars.add("var " + split[1]);
        }
    }

    String out = $FUNC.res;

    System.out.println(";IR code");
    
    String[] split = out.split("\n");
    String optimized_out = "";

    for (int i = 0; i < split.length; i++) {
        String line = split[i];
        Boolean changed = false;

        if (line.startsWith(";JUMP ")) {
            if (i + 1 < split.length) {
                if (split[i+1].startsWith(";LABEL ")) {
                    String num = line.substring(11);

                    if (num.equals(split[i+1].substring(12))) {
                        changed = true;
                        optimized_out += ";LABEL label" + num + "\n";
                        i++;
                    }
                }
            }
        }

        if (!changed) {
            optimized_out += line + "\n";
        }
    }

    System.out.println(optimized_out);
    System.out.println(";tiny code");
    for (String var : vars) {
        System.out.println(var);
    }
    System.out.println("push\npush r0\npush r1\npush r2\npush r3\njsr main\nsys halt");

    String[] new_split = optimized_out.split("\n");
    String previous_line = "";
    int local_var_num = 6;

    for (String line : new_split) {
        String[] line_split = line.split(" ");

        if (line_split[0].startsWith(";STORE")) {
            if (line_split[1].startsWith("\$T") && line_split[2].startsWith("\$T")) {
                System.out.println("move r" + (Integer.parseInt(line_split[1].substring(2))) + " r" + (Integer.parseInt(line_split[2].substring(2))));
            } else if (line_split[1].startsWith("\$L") && line_split[2].startsWith("\$L")) {
                int first_local = Integer.parseInt(line_split[1].substring(2)) * -1;
                int second_local = Integer.parseInt(line_split[2].substring(2)) * -1;
                System.out.println("move \$" + first_local + " \$" + second_local);
            } else if (line_split[1].startsWith("\$T") && line_split[2].startsWith("\$L")) {
                int second_local = Integer.parseInt(line_split[2].substring(2)) * -1;
                System.out.println("move r" + (Integer.parseInt(line_split[1].substring(2))) + " \$" + second_local);
            } else if (line_split[1].startsWith("\$L") && line_split[2].startsWith("\$T")) {
                int first_local = Integer.parseInt(line_split[1].substring(2)) * -1;
                System.out.println("move \$" + first_local + " r" + (Integer.parseInt(line_split[2].substring(2))));
            } else if (line_split[1].startsWith("\$L") && line_split[2].startsWith("\$R")) {
                int first_local = Integer.parseInt(line_split[1].substring(2)) * -1;
                System.out.println("move \$" + first_local + " r1");
                System.out.println("move r1 \$" + local_var_num);
            } else if (line_split[1].startsWith("\$T") && line_split[2].startsWith("\$R")) {
                System.out.println("move r" + (Integer.parseInt(line_split[1].substring(2))) + " \$" + local_var_num);
            } else if (line_split[2].startsWith("\$T")) {
                System.out.println("move " + line_split[1] + " r" + (Integer.parseInt(line_split[2].substring(2))));
            } else {
                System.out.println("move r" + (Integer.parseInt(line_split[1].substring(2))) + " " + line_split[2]);
            }
        } else if (line_split[0].startsWith(";MULT") || line_split[0].startsWith(";ADD") ||
                   line_split[0].startsWith(";SUB") || line_split[0].startsWith(";DIV")) {
            int final_reg = Integer.parseInt(line_split[3].substring(2));
            char type = 'r';

            if (line_split[0].startsWith(";MULT")) {
                if (line_split[0].charAt(5) == 'I') {
                    type = 'i';
                }
            } else {
                if (line_split[0].charAt(4) == 'I') {
                    type = 'i';
                }
            }

            if (line_split[1].startsWith("\$T")) {
                System.out.println("move r" + (Integer.parseInt(line_split[1].substring(2))) + " r" + final_reg);
            } else if (line_split[1].startsWith("\$P")) {
                System.out.println("move \$" + (Integer.parseInt(line_split[1].substring(2)) + 5) + " r" + final_reg);
                local_var_num = Integer.parseInt(line_split[1].substring(2)) + 6;
            } else {
                System.out.println("move " + line_split[1] + " r" + final_reg);
            }

            if (line_split[0].startsWith(";MULT")) {
                if (line_split[2].startsWith("\$T")) {
                    System.out.println("mul" + type + " r" + (Integer.parseInt(line_split[2].substring(2))) + " r" + final_reg);
                } else if (line_split[2].startsWith("\$P")) {
                    System.out.println("mul" + type + " \$" + (Integer.parseInt(line_split[2].substring(2)) + 5) + " r" + final_reg);
                    local_var_num = Integer.parseInt(line_split[2].substring(2)) + 6;
                } else {
                    System.out.println("mul" + type + " " + line_split[2] + " r" + final_reg);
                }
            } else if (line_split[0].startsWith(";ADD")) {
                if (line_split[2].startsWith("\$T")) {
                    System.out.println("add" + type + " r" + (Integer.parseInt(line_split[2].substring(2))) + " r" + final_reg);
                } else if (line_split[2].startsWith("\$P")) {
                    System.out.println("add" + type + " \$" + (Integer.parseInt(line_split[2].substring(2)) + 5) + " r" + final_reg);
                    local_var_num = Integer.parseInt(line_split[2].substring(2)) + 6;
                } else {
                    System.out.println("add" + type + " " + line_split[2] + " r" + final_reg);
                }
            } else if (line_split[0].startsWith(";SUB")) {
                if (line_split[2].startsWith("\$T")) {
                    System.out.println("sub" + type + " r" + (Integer.parseInt(line_split[2].substring(2))) + " r" + final_reg);
                } else if (line_split[2].startsWith("\$P")) {
                    System.out.println("sub" + type + " \$T" + (Integer.parseInt(line_split[2].substring(2)) + 5) + " r" + final_reg);
                    local_var_num = Integer.parseInt(line_split[2].substring(2)) + 6;
                } else {
                    System.out.println("sub" + type + " " + line_split[2] + " r" + final_reg);
                }
            } else if (line_split[0].startsWith(";DIV")) {
                if (line_split[2].startsWith("\$T")) {
                    System.out.println("div" + type + " r" + (Integer.parseInt(line_split[2].substring(2))) + " r" + final_reg);
                } else if (line_split[2].startsWith("\$P")) {
                    System.out.println("div" + type + " \$T" + (Integer.parseInt(line_split[2].substring(2)) + 5) + " r" + final_reg);
                    local_var_num = Integer.parseInt(line_split[2].substring(2)) + 6;
                } else {
                    System.out.println("div" + type + " " + line_split[2] + " r" + final_reg);
                }
            }
        } else if (line_split[0].equals(";WRITEI")) {
            if (line_split[1].startsWith("\$L")) {
                System.out.println("sys writei \$" + (Integer.parseInt(line_split[1].substring(2)) * -1));
            } else {
                System.out.println("sys writei " + line_split[1]);
            }
        } else if (line_split[0].equals(";WRITEF")) {
            if (line_split[1].startsWith("\$L")) {
                System.out.println("sys writer \$" + (Integer.parseInt(line_split[1].substring(2)) * -1));
            } else {
                System.out.println("sys writer " + line_split[1]);
            }
        } else if (line_split[0].equals(";WRITES")) {
            System.out.println("sys writes " + line_split[1]);
        } else if (line_split[0].equals(";READI")) {
            if (line_split[1].startsWith("\$L")) {
                System.out.println("sys readi \$" + (Integer.parseInt(line_split[1].substring(2)) * -1));
            } else {
                System.out.println("sys readi " + line_split[1]);
            }
        } else if (line_split[0].equals(";READF")) {
            if (line_split[1].startsWith("\$L")) {
                System.out.println("sys readr \$" + (Integer.parseInt(line_split[1].substring(2)) * -1));
            } else {
                System.out.println("sys readr " + line_split[1]);
            }
        } else if (line_split[0].equals(";READS")) {
            System.out.println("sys reads " + line_split[1]);
        } else if (line_split[0].equals(";LABEL")) {
            local_var_num = 6;
            System.out.println("label " + line_split[1]);
            System.out.println("link " + line_split[2]);
        } else if (line_split[0].equals(";JUMP")) {
            System.out.println("jmp " + line_split[1]);
        } else if (line_split[0].equals(";JSR")) {
            System.out.println("jsr " + line_split[1]);
        } else if (line_split[0].equals(";RET")) {
            System.out.println("unlnk\nret");
        } else if (line_split[0].equals(";EQ") || line_split[0].equals(";LT") || line_split[0].equals(";NE") ||
                   line_split[0].equals(";GT") || line_split[0].equals(";GE") || line_split[0].equals(";LE")) {
            char type = 'r';

            if ($glob_vars.contains("I " + line_split[1])) {
                type = 'i';
            }

            if (line_split[1].startsWith("\$T")) {
                System.out.println("cmp" + type + " r" + (Integer.parseInt(line_split[1].substring(2))) + " r" + (Integer.parseInt(line_split[1].substring(2))));
            } else {
                System.out.println("cmp" + type + " " + line_split[1] + " r" + (Integer.parseInt(line_split[2].substring(2))));
            }

            if (line_split[0].equals(";EQ")) {
                System.out.println("jeq " + line_split[3]);
            } else if (line_split[0].equals(";LT")) {
                System.out.println("jlt " + line_split[3]);
            } else if (line_split[0].equals(";NE")) {
                System.out.println("jne " + line_split[3]);
            } else if (line_split[0].equals(";GT")) {
                System.out.println("jgt " + line_split[3]);
            } else if (line_split[0].equals(";GE")) {
                System.out.println("jge " + line_split[3]);
            } else if (line_split[0].equals(";LE")) {
                System.out.println("jle " + line_split[3]);
            }
        }
        previous_line = line;
    }
    System.out.println("end");
};
decl returns [ArrayList<String> res = new ArrayList<String>();] : string_type=string_decl string_DECL=decl {
    $res.add($string_type.res);
    for (String var : $string_DECL.res) {
        $res.add(var);
        $pgm_body::glob_vars.add("S " + var);
    }
} | var_name=var_decl var_DECL=decl {
    for (String var : $var_name.res) {
        $res.add(var);
        String[] split = var.split(" ");
        $pgm_body::glob_vars.add(split[3].charAt(0) + " " + split[1]);
    }
    for (String var : $var_DECL.res) {
        $res.add(var);
    }
} | ;


/* Global String Declaration */
string_decl returns [String res] : 'STRING' ID=id ':=' VAL=str ';' {
    $res = "name " + $ID.text + " type STRING value " + $VAL.text;
};
str : STRINGLITERAL;


/* Variable Declaration */
var_decl returns [ArrayList<String> res] : TYPE=var_type ID_LIST=id_list ';' {
    String[] var_list = $ID_LIST.text.split(",");
    $res = new ArrayList<String>();
    for (String var : var_list) {
        $res.add("name " + var + " type " + $TYPE.text);
    }
} ;
var_type : 'FLOAT' | 'INT';
any_type : var_type | 'VOID';
id_list returns [ArrayList<String> res = new ArrayList<String>();] : ID=id TAIL=id_tail {
    $res.add($ID.text);
    String[] list = $TAIL.text.split(",");
    for (int i = 0; i < list.length; i++)
    {
        $res.add(list[i]);
    }
} ;
id_tail : ',' id id_tail | ;


/* Function Paramater List */
param_decl_list returns [String res] : DECL=param_decl TAIL=param_decl_tail {
    $res = $DECL.res + " " + $TAIL.res;
} | ;
param_decl returns [String res] : var_type ID=id {
    $res = $ID.text;
} ;
param_decl_tail returns [String res] : ',' PARAM=param_decl TAIL=param_decl_tail {
    $res = $PARAM.res + " " + $TAIL.res;
} | ;


/* Function Declarations */
func_declarations returns [String res = ""] : FUNC=func_decl PREV_FUNC=func_declarations {
    $res = $FUNC.res;
    $res += $PREV_FUNC.res;
} | ;
func_decl returns [String res = ""] : 'FUNCTION' any_type ID=id '('PARAMS=param_decl_list')' 'BEGIN' FUNC=func_body 'END' {
    String func = $FUNC.res.replace("\n\n", "\n");
    ArrayList<String> locals = new ArrayList<String>();

    if ($PARAMS.res != null) {
        String[] params = $PARAMS.res.split(" ");
        int i = 1;

        for (String var : $PARAMS.res.split(" ")) {
            if (!var.equals("null")) {
                func = func.replace(" " + var + " ", " \$P" + i++ + " ");
            }
        }
    }

    String[] func_split = func.split("\n");
    int local_vars = 1;
    String last_line = func_split[func_split.length - 1];

    if (!last_line.startsWith(";WRITE")) {
        String[] parts = last_line.split(" ");
        last_line = parts[0] + " " + parts[2] + " \$R\n";
    } else {
        last_line = ";STOREI 0 \$T" + $pgm_body::var_num;
        last_line += "\n;STOREI \$T" + $pgm_body::var_num + " \$R\n";
    }

    func = func.substring(0, func.length() - 1) + last_line;
    int num = 0;

    for (String line : func_split) {
        String[] line_split = line.split(" ");
        int i = 0;

        if (line.startsWith(";POP") && num < func_split.length) {
            if (func_split[num + 1].startsWith(";STORE")) {
                String[] parts = func_split[num + 1].split(" ");
                func = func.replace(line + "\n" + func_split[num + 1], ";POP\n;POP " + parts[1] + "\n" + func_split[num + 1]);
            }
        }

        for (String var : line_split) {
            if (var.matches("^[a-zA-Z][a-zA-Z0-9]*")) {
                if (line_split[0].startsWith(";STORE") && line_split[1].equals(var)) {
                    locals.add(var);
                } else if (!locals.contains(var) && !line_split[0].startsWith(";WRITE") && !line_split[0].startsWith(";READ")) {
                    func = func.replace(" " + var + " ", " \$L" + local_vars + " ");
                    func = func.replace(" " + var + "\n", " \$L" + local_vars++ + "\n");
                }
            } else if (var.matches("^_[a-zA-Z][a-zA-Z0-9]*")) {
                func = func.replace(var, var.substring(1, var.length()));
            }
        }
        num++;
    }

    $res = ";LABEL " + $ID.text + " " + (local_vars - 1) + "\n;LINK\n";
    $res += func.replace("  ", " ");
    $res += ";RET\n\n";
};
func_body returns [String res = ""] : decl STMT=stmt_list {
    $res = $STMT.res;
};


/* Statement List */
stmt_list returns [String res = ""] : STMT=stmt STMT_LIST=stmt_list {
    $res = $STMT.res + "\n" + $STMT_LIST.res;
} | ;
stmt returns [String res = ""] : BASE=base_stmt {
    $res = $BASE.res;
} | IF=if_stmt {
    $res = $IF.res;
} | FOR=for_stmt {
    $res = $FOR.res;
} ;
base_stmt returns [String res = ""] : ASSIGN=assign_stmt {
    $res = $ASSIGN.res;
} | READ=read_stmt {
    $res = $READ.res;
} | WRITE=write_stmt {
    $res = $WRITE.res;
} | return_stmt;


/* Basic Statements */
assign_stmt returns [String res = ""] : ASSIGN=assign_expr ';' {
    $res = $ASSIGN.res;
} ;
assign_expr returns [String res = ""] : ID=id ':=' EXPR=expr {
    String[] split = $EXPR.res.split(" ");
    int i = 0;
    int x = 0;
    String type = "I";

    for (String line : split) {
        if (line.contains("_")) {
            line = line.substring(0, line.length() - 1);
            split[x] = split[x].substring(0, split[x].length() - 1);
            $res += line.replace("_", " ");
            $res += "\n";
        }
        x++;
    }

    String[] new_split = new String[split.length];

    if ($pgm_body::glob_vars.contains("I " + $ID.text)) {
        type = "I";
    } else {
        type = "F";
    }

    for (String var : split) {
        if (var != null && !var.equals("null") && !var.equals("(") && !var.equals(")")) {
            if (var.contains("_")) {
                var = var.substring(var.lastIndexOf("_") + 1);
            }
            new_split[i++] = var;
        }
    }

    if (new_split[0].equals("CALL")) {
        int num = 0;

        $res += ";PUSH\n";
        for (int j = 2; j < i; j++) {
            if (!new_split[j].equals("null")) {
                num++;
                $res += ";PUSH " + new_split[j] + " \n";
            }
        }
        $res += ";JSR _" + new_split[1] + "\n";
        $res += ";POP\n";
        for (int j = 0; j < num - 1; j++) {
            $res += ";POP\n";
        }
    }

    if (i <= 2) {
        $res += ";STORE" + type + " " + new_split[0] + " \$T" + $pgm_body::var_num + "\n";
        $res += ";STORE" + type + " \$T" + $pgm_body::var_num++ + " " + $ID.text + "\n";
    } else {
        while (i > 1) {
            char op = new_split[1].charAt(0);
            Boolean follows = false;
            int ind = 0;
            
            if (op != '*' && op != '/') {
                for (int j = 2; j < i; j++) {
                    if (new_split[j].charAt(0) == '*' || new_split[j].charAt(0) == '/') {
                        follows = true;
                        ind = j;
                        break;
                    }
                }
            }

            if (op == '*') {
                $res += ";MULT" + type + " " + new_split[0] + " " + new_split[2] + " \$T" + $pgm_body::var_num++ + "\n";
            } else if (op == '/') {
                $res += ";DIV" + type + " " + new_split[0] + " " + new_split[2] + " \$T" + $pgm_body::var_num++ + "\n";
            } else if (op == '+' && follows == false) {
                $res += ";ADD" + type + " " + new_split[0] + " " + new_split[2] + " \$T" + $pgm_body::var_num++ + "\n";
            } else if (op == '-' && follows == false) {
                $res += ";SUB" + type + " " + new_split[0] + " " + new_split[2] + " \$T" + $pgm_body::var_num++ + "\n";
            } else if (follows == true) {
                if (new_split[ind].charAt(0) == '*') {
                    $res += ";MULT" + type + " " + new_split[ind-1] + " " + new_split[ind+1] + " \$T" + $pgm_body::var_num++ + "\n";
                } else if (new_split[ind].charAt(0) == '/') {
                    $res += ";DIV" + type + " " + new_split[ind-1] + " " + new_split[ind+1] + " \$T" + $pgm_body::var_num++ + "\n";
                }
                new_split[ind-1] = "\$T" + ($pgm_body::var_num - 1);

                for (int j = ind; j < i-2; j++) {
                    new_split[j] = new_split[j+2];
                }
            }

            if (!follows) {
                new_split[0] = "\$T" + ($pgm_body::var_num - 1);
                for (int j = 1; j < i-2; j++) {
                    new_split[j] = new_split[j+2];
                }
            }

            for (int j = i-2; j <= i; j++) {
                new_split[j] = null;
            }

            i -= 2;
        }
        $res += ";STORE" + type + " \$T" + ($pgm_body::var_num-1) + " " + $ID.text + "\n";
    }
} ;
read_stmt returns [String res = ""] : 'READ' '(' ID_LIST=id_list ')'';' {
    for (String var : $ID_LIST.res) {
        if (!var.equals("")) {
            if ($pgm_body::glob_vars.contains("I " + var)) {
                $res += ";READI " + var + "\n";
            } else if ($pgm_body::glob_vars.contains("F " + var)) {
                $res += ";READF " + var + "\n";
            } else {
                $res += ";READS " + var + "\n";
            }
        }
    }
};
write_stmt returns [String res = ""] : 'WRITE' '(' ID_LIST=id_list ')'';' {
    for (String var : $ID_LIST.res) {
        if (!var.equals("")) {
            if ($pgm_body::glob_vars.contains("I " + var)) {
                $res += ";WRITEI " + var + "\n";
            } else if ($pgm_body::glob_vars.contains("F " + var)) {
                $res += ";WRITEF " + var + "\n";
            } else {
                $res += ";WRITES " + var + "\n";
            }
        }
    }
};
return_stmt : 'RETURN' expr ';';


/* Expressions */
expr returns [String res] : EXP=expr_prefix FACTOR=factor {
    $res = $EXP.res + " " + $FACTOR.res;
} ;
expr_prefix returns [String res] : EXP=expr_prefix FACTOR=factor OP=addop {
    $res = $EXP.res + " " + $FACTOR.res + " " + $OP.text;
} | ;
factor returns [String res] : FAC=factor_prefix POST=postfix_expr {
    $res = $FAC.res + " " + $POST.res;
} ;
factor_prefix returns [String res] : factor_prefix POST=postfix_expr OP=mulop {
    $res = $POST.res + " " + $OP.text;
} | ;
postfix_expr returns [String res] : PRIMARY=primary {
    $res = $PRIMARY.res;
} | CALL=call_expr {
    $res = "CALL " + $CALL.res;
};
call_expr returns [String res] : ID=id '(' EXPR=expr_list ')' {
    $res = $ID.text + " " + $EXPR.res;
};
expr_list returns [String res] : EXP=expr EXP_TAIL=expr_list_tail {
    $res = $EXP.res + " " + $EXP_TAIL.res;
} | ;
expr_list_tail returns [String res] : ',' EXP=expr EXP_TAIL=expr_list_tail {
    $res = $EXP.res + " " + $EXP_TAIL.res;
} | ;
primary returns [String res] : '(' EXP=expr ')' {
    $res = "( " + $EXP.res + " )";

    String[] split = $EXP.res.split(" ");
    int i = 0;
    String[] new_split = new String[split.length];
    String type = "I";

    $res = "";

    for (String var : split) {
        if (!var.equals("null") && !var.equals("(") && !var.equals(")")) {
            new_split[i++] = var;
        }
    }

    if ($pgm_body::glob_vars.contains("I " + new_split[0])) {
        type = "I";
    } else {
        type = "F";
    }

    while (i > 1) {
        char op = new_split[1].charAt(0);
        Boolean follows = false;
        int ind = 0;

        for (int j = 2; j < i; j++) {
            if (new_split[j].charAt(0) == '*' || new_split[j].charAt(0) == '/') {
                follows = true;
                ind = j;
                break;
            }
        }

        if (op == '*') {
            $res += ";MULT" + type + "_" + new_split[0] + "_" + new_split[2] + "_\$T" + $pgm_body::var_num++ + "\n";
        } else if (op == '/') {
            $res += ";DIV" + type + "_" + new_split[0] + "_" + new_split[2] + "_\$T" + $pgm_body::var_num++ + "\n";
        } else if (op == '+' && follows == false) {
            $res += ";ADD" + type + "_" + new_split[0] + "_" + new_split[2] + "_\$T" + $pgm_body::var_num++ + "\n";
        } else if (op == '-' && follows == false) {
            $res += ";SUB" + type + "_" + new_split[0] + "_" + new_split[2] + "_\$T" + $pgm_body::var_num++ + "\n";
        } else if (follows == true) {
            if (new_split[ind].charAt(0) == '*') {
                $res += ";MULT" + type + "_" + new_split[ind-1] + "_" + new_split[ind+1] + "_\$T" + $pgm_body::var_num++ + "\n";
            } else if (new_split[ind].charAt(0) == '/') {
                $res += ";DIV" + type + "_" + new_split[ind-1] + "_" + new_split[ind+1] + "_\$T" + $pgm_body::var_num++ + "\n";
            }
            new_split[ind-1] = "\$T" + ($pgm_body::var_num - 1);

            for (int j = ind; j < i-2; j++) {
                new_split[j] = new_split[j+2];
            }
        }

        if (!follows) {
            new_split[0] = "\$T" + ($pgm_body::var_num - 1);
            for (int j = 1; j < i-2; j++) {
                new_split[j] = new_split[j+2];
            }
        }

        for (int j = i-2; j <= i; j++) {
            new_split[j] = null;
        }

        i -= 2;
    }
} | ID=id {
    $res = $ID.text;
} | in=INTLITERAL {
    $res = $in.text;
} | flo=FLOATLITERAL {
    $res = $flo.text;
} ;
addop : '+' | '-';
mulop : '*' | '/';


/* Complex Statements and Condition */
if_stmt returns [String res = ""] : 'IF' '(' COND=cond ')' DECL=decl STMT=stmt_list ELSE=else_part 'FI' {
    String[] ops = {"!=", "=", "<=", ">=", "<", ">"};
    String[] instructions = {";EQ", ";NE", ";GT", ";LT", ";GE", ";LE"};
    String[] cond_split = $COND.res.split(" ");
    String[] new_cond_split = new String[cond_split.length];
    int j = 0, x = 0;

    for (String line : cond_split) {
        if (line.contains("_")) {
            line = line.substring(0, line.length() - 1);
            String[] split = line.split("_");
            cond_split[x] = split[split.length - 1];
            $res += line.replace("_", " ") + "\n";
        }
        x++;
    }

    for (int i = 0; i < cond_split.length; i++) {
        String var = cond_split[i];
        if (var != null && !var.equals("null")) {
            new_cond_split[j++] = var;
        }
    }

    $res += ";STOREI " + new_cond_split[2] + " \$T" + $pgm_body::var_num + "\n";
    $res += instructions[Arrays.asList(ops).indexOf(new_cond_split[1])]+ " " + new_cond_split[0] + " \$T" + $pgm_body::var_num + " label" + ($pgm_body::label_num) + "\n";
    $res += $STMT.res;
    $res += ";JUMP label" + ($pgm_body::label_num + 1) + "\n";
    $res += ";LABEL label" + $pgm_body::label_num + "\n";
    $res += $ELSE.res;
    $res += ";JUMP label" + ($pgm_body::label_num + 1) + "\n";
    $res += ";LABEL label" + ($pgm_body::label_num + 1) + "\n";

    $pgm_body::label_num += 2;
} ;
else_part returns [String res = ""] : 'ELSE' DECL=decl STMT=stmt_list {
    $res = $STMT.res;
} | ;
cond returns [String res = ""] : EXPR=expr OP=compop EXPR2=expr {
    $res = $EXPR.res + " " + $OP.text + " " + $EXPR2.res;
} ;
compop : '<' | '>' | '=' | '!=' | '<=' | '>=';

init_stmt returns [String res = ""] : ASSIGN=assign_expr {
    $res = $ASSIGN.res;
} | ;
incr_stmt returns [String res = ""] : ASSIGN_EXPR=assign_expr {
    $res = $ASSIGN_EXPR.res;
} | ;

for_stmt returns [String res = ""]: 'FOR' '(' INIT=init_stmt ';' COND=cond ';' INCR=incr_stmt ')' DECL=decl STMT=stmt_list 'ROF' {
    String[] ops = {"!=", "=", "<=", ">=", "<", ">"};
    String[] instructions = {";EQ", ";NE", ";GT", ";LT", ";GE", ";LE"};

    $res = $INIT.res;
    $res += ";LABEL label" + $pgm_body::label_num + "\n";

    String[] cond_split = $COND.res.split(" ");
    String[] new_cond_split = new String[cond_split.length];
    int j = 0, x = 0;

    for (String line : cond_split) {
        if (line.contains("_")) {
            line = line.substring(0, line.length() - 1);
            String[] split = line.split("_");
            cond_split[x] = split[split.length - 1];
            $res += line.replace("_", " ") + "\n";
        }
        x++;
    }

    for (int i = 0; i < cond_split.length; i++) {
        String var = cond_split[i];
        if (var != null && !var.equals("null")) {
            new_cond_split[j++] = var;
        }
    }

    $res += ";STOREI " + new_cond_split[2] + " \$T" + $pgm_body::var_num + "\n";
    $res += instructions[Arrays.asList(ops).indexOf(new_cond_split[1])] + " " + new_cond_split[0] + " \$T" + $pgm_body::var_num + " label" + ($pgm_body::label_num + 2) + "\n";
    $res += $STMT.res;
    $res += ";LABEL label" + ($pgm_body::label_num + 1) + "\n";
    $res += $INCR.res;
    $res += ";JUMP label" + $pgm_body::label_num + "\n";
    $res += ";LABEL label" + ($pgm_body::label_num + 2) + "\n";

    $pgm_body::label_num += 2;
} ;
