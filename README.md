# Multiway Tree in Pure Perl

![Test](https://github.com/philiprbrenan/TreeMulti/workflows/Test/badge.svg)

    # Insert keys into a multiway [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)) 
      local $keysPerNode = 15;
      my $t = new;
      for my $i(1..256)
       {$t = insert($t, $i, 2*$i);
       }
      is_deeply $t->printKeys, <<END;
     72 144
       9 18 27 36 45 54 63
         1 2 3 4 5 6 7 8
         10 11 12 13 14 15 16 17
         19 20 21 22 23 24 25 26
         28 29 30 31 32 33 34 35
         37 38 39 40 41 42 43 44
         46 47 48 49 50 51 52 53
         55 56 57 58 59 60 61 62
         64 65 66 67 68 69 70 71
       81 90 99 108 117 126 135
         73 74 75 76 77 78 79 80
         82 83 84 85 86 87 88 89
         91 92 93 94 95 96 97 98
         100 101 102 103 104 105 106 107
         109 110 111 112 113 114 115 116
         118 119 120 121 122 123 124 125
         127 128 129 130 131 132 133 134
         136 137 138 139 140 141 142 143
       153 162 171 180 189 198 207 216 225 234 243
         145 146 147 148 149 150 151 152
         154 155 156 157 158 159 160 161
         163 164 165 166 167 168 169 170
         172 173 174 175 176 177 178 179
         181 182 183 184 185 186 187 188
         190 191 192 193 194 195 196 197
         199 200 201 202 203 204 205 206
         208 209 210 211 212 213 214 215
         217 218 219 220 221 222 223 224
         226 227 228 229 230 231 232 233
         235 236 237 238 239 240 241 242
         244 245 246 247 248 249 250 251 252 253 254 255 256
    END
