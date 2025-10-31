TARGET		= bs_validator
CXX			= g++
CXXFLAGS	= -Wall -Wextra -Werror -I. -O3 -std=c++11
LDFLAGS		= -lm

SRC			= main.cpp
OBJ_DIR		= objects
OBJS		= $(patsubst %.cpp, $(OBJ_DIR)/%.o,$(SRC))
HEADERS		= bs_call_price.hpp bs_templated_cdf_dispatcher.hpp bs_greeks.hpp bs_templated_pricer.hpp

all:	$(TARGET)

$(TARGET):	$(OBJS)
	@echo "Linking executable..."
	$(CXX) $(CXXFLAGS) $(OBJS) -o $(TARGET) $(LDFLAGS)

$(OBJ_DIR)/%.o: %.cpp $(HEADERS) | $(OBJ_DIR)
	@echo "Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR):
		@mkdir -p $@

clean:
	rm -rf $(OBJ_DIR)

fclean:	clean
	rm -f $(TARGET)
	rm -f *.csv

re: fclean all

run:	all
	@echo "--- Running validation (Generating CSVs) ---"
	./$(TARGET)

.PHONY:	all clean run